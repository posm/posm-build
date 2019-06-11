#!/bin/bash

dst=/opt/osm
osmosis_ver="${osmosis_ver:-0.46}"
pgsql_ver="${pgsql_ver:-10}"
ruby_prefix="${ruby_prefix:-/opt/rbenv}"

configure_osm_replication() {
  mkdir -p /opt/data/osm/replication/minute
  chown -R osm:osm /opt/data/osm/replication

  mkdir -p /etc/osmosis
  expand etc/osmosis/osm.properties /etc/osmosis/osm.properties

  # initialize minutely replication
  sudo -u osm osmosis \
    --replicate-apidb \
      authFile=/etc/osmosis/osm.properties \
      validateSchemaVersion=no \
    --write-replication \
      workingDirectory=/opt/data/osm/replication/minute

  expand etc/systemd/system/osmosis-replication.service /etc/systemd/system/osmosis-replication.service
  expand etc/systemd/system/osmosis-replication.timer /etc/systemd/system/osmosis-replication.timer
  systemctl enable --now osmosis-replication.timer
  # run the service to kick things off
  systemctl start osmosis-replication.service
}

# requires nodejs, postgis
deploy_osm_rails_ubuntu() {
  apt-get install --no-install-recommends -y \
    libmagickwand-dev libxml2-dev libxslt1-dev build-essential \
     postgresql-contrib-${pgsql_ver} libpq-dev postgresql-server-dev-${pgsql_ver} \
     libsasl2-dev imagemagick

  # OSM user & env
  useradd -c 'OpenStreetMap' -d "$dst" -m -r -s /bin/bash -U osm
  mkdir -p "$dst"
  chown osm:osm "$dst"
  cat - << "EOF" > "$dst/.bashrc"
# this is for interactive shells
for d in "$HOME" "$HOME"/osm-*; do
  if [ -e "$d/bin" ]; then
    PATH="$PATH:$d/bin"
  fi
  if [ -e "$d/.env" ]; then
    set -a
    . "$d/.env"
    set +a
  fi
done
EOF
}

deploy_osm_rails_common() {
  deploy_osm_rails

  apps=$(jq .apps /opt/posm-www/config.json)
  new_apps=$(cat << EOF | jq -s '.[0] + .[1] | unique'
[
  {
    "name": "OpenStreetMap",
    "icon": "send-to-map",
    "url": "//${osm_fqdn}/"
  }
]
$apps
EOF
)

  config=$(jq . /opt/posm-www/config.json)
  cat << EOF | jq -s '.[0] * .[1]' > /opt/posm-www/config.json
$config
{
  "apps": $new_apps
}
EOF
}

deploy_osm_rails() {
  export PATH="$PATH:$ruby_prefix/bin:$ruby_prefix/plugins/ruby-build/bin"
  export RBENV_ROOT="$ruby_prefix"
  eval "$(rbenv init -)"

  # gems
  type bundler || gem install --no-rdoc --no-ri bundler -v 1.11.2

  # npm modules
  npm install -g svgo

  # install OSM WEB
  from_github "https://github.com/AmericanRedCross/openstreetmap-website" "$dst/osm-web" "posm-v0.8.0"
  chown -R osm:osm "$dst/osm-web"

  # service-friendly serving + logging
  grep puma "$dst/osm-web/Gemfile" || echo "gem 'puma'" >> "$dst/osm-web/Gemfile"
  grep rails_stdout_logging "$dst/osm-web/Gemfile" || echo "gem 'rails_stdout_logging'" >> "$dst/osm-web/Gemfile"

  # configure OSM
  expand etc/osm-puma.rb "$dst/osm-web/config/puma.rb"
  expand etc/osm-actionmailer.rb "$dst/osm-web/config/initializers/action_mailer.rb"

  # use the stock configurations; we'll override them with environment variables
  cp "$dst/osm-web/config/example.database.yml" "$dst/osm-web/config/database.yml"
  cp "$dst/osm-web/config/example.application.yml" "$dst/osm-web/config/application.yml"

  # configure OSM
  export ruby_prefix
  expand etc/osm-web.env "$dst/osm-web/.env"
  chown osm:osm "$dst/osm-web/.env"

  # install vendored deps
  su - osm -c "cd '$dst/osm-web' && bundle install -j `nproc` --path vendor/bundle --with production"
  su - osm -c "rm -rf '$dst/osm-web/vendor/bundle/ruby/*/cache'"

  # init database
  echo -e "${osm_pg_pass}\n${osm_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$osm_pg_owner'"
  su - postgres -c "createdb --owner='$osm_pg_owner' '$osm_pg_dbname'"
  su - postgres -c "psql --dbname='$osm_pg_dbname' --command='CREATE EXTENSION btree_gist'"

  su - osm -c "cd '$dst/osm-web/db/functions' && make libpgosm.so"
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '$dst/osm-web/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT\""
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '$dst/osm-web/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT\""
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '$dst/osm-web/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT\""

  su - osm -c "cd '$dst/osm-web' && bundle exec rake db:migrate"

  su - osm -c "sed -i -e \"s/posm.io/${posm_fqdn}/\" $dst/osm-web/app/assets/javascripts/id.js"
  su - osm -c "sed -i -e \"s/posm.io/${posm_fqdn}/\" $dst/osm-web/app/assets/javascripts/leaflet.map.js"

  # assets
  su - osm -c "cd '$dst/osm-web' && bundle exec rake assets:precompile"

  # generate credentials for OSM's iD
  export osm_id_key=$(su - osm -c "cd '$dst/osm-web' && bundle exec rake osm:apps:create name='OSM iD' url='${osm_base_url}'" | jq -r .key)

  # create a default user
  su - osm -c "cd '$dst/osm-web' && bundle exec rake osm:users:create display_name='${osm_posm_user}' description='${osm_posm_description}'"

  # update the systemd unit and restart
  expand etc/systemd/system/osm-web.service.hbs /etc/systemd/system/osm-web.service
  systemctl enable --now osm-web

  # create backup directory
  mkdir -p /opt/data/backups/osm
  chown osm:osm /opt/data/backups/osm
  chmod 755 /opt/data/backups/osm

  # add the nginx config for the OSM virtualhost
  expand etc/nginx-osm.conf /etc/nginx/sites-available/osm
  ln -s -f ../sites-available/osm /etc/nginx/sites-enabled/
  service nginx restart

  true
}

deploy_osm_cgimap_ubuntu() {
  apt-get install --no-install-recommends -y \
    libboost-date-time1.65.1 libboost-filesystem1.65.1 libboost-locale1.65.1 \
    libboost-regex1.65.1 libboost-serialization1.65.1 libboost-system1.65.1 \
    libboost-thread1.65.1 libcrypto++6 libfcgi0ldbl libhashkit2 libmemcached11 \
    libmemcachedutil2 libpqxx-4.0v5 \
    libxml2-dev libpqxx-dev libfcgi-dev libboost-dev libboost-regex-dev \
    libboost-program-options-dev libboost-date-time-dev \
    libboost-filesystem-dev libboost-system-dev libboost-locale-dev \
    libmemcached-dev libcrypto++-dev build-essential automake autoconf \
    libtool
}

cleanup_osm_cgimap_ubuntu() {
  apt purge -y \
    autoconf automake autotools-dev libboost-date-time-dev \
    libboost-date-time1.65-dev libboost-dev libboost-filesystem-dev \
    libboost-filesystem1.65-dev libboost-locale-dev libboost-locale1.65-dev \
    libboost-program-options-dev libboost-program-options1.65-dev \
    libboost-regex-dev libboost-regex1.65-dev libboost-serialization1.65-dev \
    libboost-system-dev libboost-system1.65-dev libboost1.65-dev \
    libcrypto++-dev libfcgi-dev libhashkit-dev libmemcached-dev libpqxx-dev \
    libtool m4
}

deploy_osm_cgimap_common() {
  test -f '$dst/osm-cgimap/openstreetmap-cgimap' || deploy_osm_cgimap
}

deploy_osm_cgimap() {
  from_github "https://github.com/posm/openstreetmap-cgimap" "$dst/osm-cgimap" "v0.6.0"
  chown -R osm:osm "$dst/osm-cgimap"

  su - osm -c "cd '$dst/osm-cgimap' && ./autogen.sh"
  su - osm -c "cd '$dst/osm-cgimap' && ./configure"
  su - osm -c "cd '$dst/osm-cgimap' && make -j $(nproc)"

  expand etc/systemd/system/osm-cgimap.service.hbs /etc/systemd/system/osm-cgimap.service
  systemctl enable --now osm-cgimap

  true
}

deploy_osm_ubuntu() {
  apt-get install --no-install-recommends -y \
    osmctools osm2pgsql osmium-tool

  deploy_osmosis_prebuilt

  deploy_osm_rails_ubuntu
  deploy_osm_rails_common

  deploy_osm_cgimap_ubuntu
  deploy_osm_cgimap_common
  cleanup_osm_cgimap_ubuntu

  configure_osm_replication
}

deploy_osmosis_prebuilt() {
  local dst="/opt/osmosis"

  mkdir -p "${BOOTSTRAP_HOME}/sources"
  wget -N -P "${BOOTSTRAP_HOME}/sources" "http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-${osmosis_ver}.tgz"

  mkdir -p "$dst"
  tar -zxf "${BOOTSTRAP_HOME}/sources/osmosis-${osmosis_ver}.tgz" -C "$dst"
  chown -R root:root "$dst"
  chmod -R o-w "$dst"

  ln -s -f "$dst/bin/osmosis" /usr/bin/
}

deploy osm
