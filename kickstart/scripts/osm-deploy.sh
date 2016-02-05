#!/bin/bash

dst=/opt/osm
osmosis_ver="${osmosis_ver:-0.44.1}"

# requires nodejs, postgis
deploy_osm_rails_ubuntu() {
  apt-get install -y \
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
  from_github "https://github.com/AmericanRedCross/openstreetmap-website" "$dst/osm-web"
  chown -R osm:osm "$dst/osm-web"

  # add Puma so `rails server` will use it
  grep puma "$dst/osm-web/Gemfile" || echo "gem 'puma'" >> "$dst/osm-web/Gemfile"
  grep rails_stdout_logging "$dst/osm-web/Gemfile" || echo "gem 'rails_stdout_logging'" >> "$dst/osm-web/Gemfile"

  # configure OSM
  expand etc/osm-application.yml "$dst/osm-web/config/application.yml"
  expand etc/osm-database.yml "$dst/osm-web/config/database.yml"
  expand etc/osm-puma.rb "$dst/osm-web/config/puma.rb"
  expand etc/osm-actionmailer.rb "$dst/osm-web/config/initializers/action_mailer.rb"
  expand etc/osm-config.ru "$dst/osm-web/config.ru"

  # configure FP
  expand etc/osm-web.env "$dst/osm-web/.env"

  # install vendored deps
  su - osm -c "cd '$dst/osm-web' && bundle install --quiet -j `nproc` --path vendor/bundle"

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

  # start
  expand etc/osm-web.upstart /etc/init/osm-web.conf
  start osm-web
}

deploy_osm_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:kakrueger/openstreetmap -y
  apt-get update
  apt-get install -y \
    default-jre-headless
  apt-get install -y \
    libmapnik2.2 \
    libmapnik2-dev \
    osmpbf-bin libosmpbf-dev \
    python-gdal \
    geotiff-bin \
    ttf-baekmuk

  ubuntu_backport_install osmctools
  ubuntu_backport_install osm2pgsql
  deploy_osmosis_prebuilt

  #backport_osmosis

  deploy_osm_rails_ubuntu
  deploy_osm_rails_common
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


backport_osmosis() {
  # extra build deps for osmosis
  apt-get install -y \
    default-jdk ivy junit4 ant-optional maven-repo-helper \
    libbatik-java libcommons-codec-java libcommons-compress-java libcommons-dbcp-java libjpf-java libmysql-java libpostgis-java libpostgresql-jdbc-java libspring-beans-java libspring-context-java libspring-jdbc-java libspring-transaction-java libstax2-api-java libosmpbf-java libplexus-classworlds-java libprotobuf-java libwoodstox-java libxz-java
  ubuntu_backport_install netty-3.9

  ubuntu_backport_install gradle-debian-helper # this fails

  # finally backport osmosis itself
  ubuntu_backport_install osmosis
}

deploy osm
