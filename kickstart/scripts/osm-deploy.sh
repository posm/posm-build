#!/bin/bash

dst=/opt/osm
osmosis_ver="${osmosis_ver:-0.44.1}"

# requires nodejs, postgis
deploy_osm_rails_ubuntu() {
  apt-get install --no-install-recommends -y \
    libmagickwand-dev libxml2-dev libxslt1-dev build-essential \
     postgresql-contrib libpq-dev postgresql-server-dev-all \
     libsasl2-dev imagemagick

  # OSM user & env
  useradd -c 'OpenStreetMap' -d "$dst" -m -r -s /bin/bash -U osm
  mkdir -p "$dst"
  chown osm:osm "$dst"
  cat - <<"EOF" >"$dst/.bashrc"
    # this is for interactive shell, not used by upstart!
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
}

deploy_osm_rails() {
  # gems
  type bundler || gem install --no-rdoc --no-ri bundler

  # npm modules
  npm install -g svgo

  # install OSM WEB
  from_github "https://github.com/AmericanRedCross/openstreetmap-website" "$dst/osm-web" "posm"
  chown -R osm:osm "$dst/osm-web"

  # upstart-friendly serving + logging
  grep puma "$dst/osm-web/Gemfile" || echo "gem 'puma'" >> "$dst/osm-web/Gemfile"
  grep rails_stdout_logging "$dst/osm-web/Gemfile" || echo "gem 'rails_stdout_logging'" >> "$dst/osm-web/Gemfile"

  # configure OSM
  expand etc/osm-puma.rb "$dst/osm-web/config/puma.rb"
  expand etc/osm-actionmailer.rb "$dst/osm-web/config/initializers/action_mailer.rb"

  # use the stock configurations; we'll override them with environment variables
  cp "$dst/osm-web/config/example.database.yml" "$dst/osm-web/config/database.yml"
  cp "$dst/osm-web/config/example.application.yml" "$dst/osm-web/config/application.yml"

  # configure OSM
  expand etc/osm-web.env "$dst/osm-web/.env"

  # install vendored deps
  su - osm -c "cd '$dst/osm-web' && bundle install -j `nproc` --path vendor/bundle --with production"

  # init database
  echo -e "${osm_pg_pass}\n${osm_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$osm_pg_owner'"
  su - postgres -c "createdb --owner='$osm_pg_owner' '$osm_pg_dbname'"
  su - postgres -c "psql --dbname='$osm_pg_dbname' --command='CREATE EXTENSION btree_gist'"

  su - osm -c "cd '$dst/osm-web/db/functions' && make libpgosm.so"
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION maptile_for_point(int8, int8, int4) RETURNS int4 AS '$dst/osm-web/db/functions/libpgosm', 'maptile_for_point' LANGUAGE C STRICT\""
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION tile_for_point(int4, int4) RETURNS int8 AS '$dst/osm-web/db/functions/libpgosm', 'tile_for_point' LANGUAGE C STRICT\""
  su - postgres -c "psql -d $osm_pg_dbname -c \"CREATE FUNCTION xid_to_int4(xid) RETURNS int4 AS '$dst/osm-web/db/functions/libpgosm', 'xid_to_int4' LANGUAGE C STRICT\""

  su - osm -c "cd '$dst/osm-web' && bundle exec rake db:migrate"

  # assets
  su - osm -c "cd '$dst/osm-web' && bundle exec rake assets:precompile"

  # generate credentials for OSM's iD
  export osm_id_key=$(su - osm -c "cd '$dst/osm-web' && bundle exec rake osm:apps:create name='OSM iD' url='${posm_base_url}'" | jq -r .key)

  # create a default user
  su - osm -c "cd '$dst/osm-web' && bundle exec rake osm:users:create display_name='${osm_posm_user}' description='${osm_posm_description}'"

  # update the upstart config
  expand etc/osm-web.upstart /etc/init/osm-web.conf

  # start
  service osm-web restart

  # add the nginx config for the OSM virtualhost
  expand etc/nginx-osm.conf /etc/nginx/sites-available/osm
  ln -s -f ../sites-available/osm /etc/nginx/sites-enabled/
  service nginx restart

  true
}

deploy_osm_cgimap_ubuntu() {
  apt-get install --no-install-recommends -y \
    libxml2-dev libpqxx3-dev libfcgi-dev libboost-dev libboost-regex-dev \
    libboost-program-options-dev libboost-date-time-dev \
    libboost-filesystem-dev libboost-system-dev libmemcached-dev \
    build-essential automake autoconf libtool
}

deploy_osm_cgimap_common() {
  test -f '$dst/osm-cgimap/map' || deploy_osm_cgimap
}

deploy_osm_cgimap() {
  from_github "https://github.com/AmericanRedCross/openstreetmap-cgimap" "$dst/osm-cgimap"
  chown -R osm:osm "$dst/osm-cgimap"

  su - osm -c "cd '$dst/osm-cgimap' && ./autogen.sh"
  su - osm -c "cd '$dst/osm-cgimap' && ./configure"
  su - osm -c "cd '$dst/osm-cgimap' && make -j $(nproc)"

  expand etc/osm-cgimap.upstart /etc/init/osm-cgimap.conf
  service osm-cgimap restart

  true
}

deploy_osm_ubuntu() {
  apt-get install --no-install-recommends -y software-properties-common
  add-apt-repository -s -y ppa:kakrueger/openstreetmap
  apt-get update
  apt-get install --no-install-recommends -y \
    default-jre-headless \
    osmpbf-bin libosmpbf-dev

  type osmconvert || ubuntu_backport_install osmctools
  type osm2pgsql || ubuntu_backport_install osm2pgsql
  deploy_osmosis_prebuilt

  deploy_osm_rails_ubuntu
  deploy_osm_rails_common

  deploy_osm_cgimap_ubuntu
  deploy_osm_cgimap_common
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
