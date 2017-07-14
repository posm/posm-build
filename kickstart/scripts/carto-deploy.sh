#!/bin/bash

carto_user="${carto_user:-${osm_carto_pg_owner:-gis}}"
carto_styles="${carto_styles:-posm}"
dst="/opt/$carto_user"
tessera_config_dir=/etc/tessera.conf.d

deploy_carto_ubuntu() {
  apt-get install --no-install-recommends -y unzip make postgresql-contrib
  useradd -c 'OSM/GIS User' -d "$dst" -m -r -s /bin/bash -U "$carto_user"
  mkdir -p $tessera_config_dir
  chown $carto_user:$carto_user $tessera_config_dir
  chmod a+rwx $tessera_config_dir
  echo -e "${osm_carto_pg_pass}\n${osm_carto_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$osm_carto_pg_owner'"
  su - postgres -c "createdb --owner='$osm_carto_pg_owner' '$osm_carto_pg_dbname'"
  su - postgres -c "psql --dbname='$osm_carto_pg_dbname' --command='CREATE EXTENSION postgis'"
  su - postgres -c "psql --dbname='$osm_carto_pg_dbname' --command='CREATE EXTENSION hstore'"
  su - postgres -c "createdb --owner='$osm_carto_pg_owner' '$osm_carto_pg_temp_dbname'"
  su - postgres -c "psql --dbname='$osm_carto_pg_temp_dbname' --command='CREATE EXTENSION postgis'"
  su - postgres -c "psql --dbname='$osm_carto_pg_temp_dbname' --command='CREATE EXTENSION hstore'"
  su - postgres -c "psql -d postgres -c 'ALTER USER $carto_user CREATEDB;'"

  expand etc/apply-updates.sh /usr/local/bin/apply-updates.sh
  chmod +x /usr/local/bin/apply-updates.sh

  su - postgres -c "pg_restore --dbname='$osm_carto_pg_dbname'" < "${BOOTSTRAP_HOME}/etc/gis.pgdump"

  local s
  for s in $carto_styles; do
    local fn="deploy_carto_$s"
    $fn
  done
}

deploy_carto_posm() {
  from_github "https://github.com/AmericanRedCross/posm-carto" "$dst/posm-carto"
  chown -R "$carto_user:$carto_user" "$dst/posm-carto"

  expand etc/posm-carto.env "$dst/posm-carto/.env"
  chown $carto_user:$carto_user "$dst/posm-carto/.env"

  sudo -EHu "$carto_user" bash -c "cd '$dst/posm-carto' && npm install --quiet"
  sudo -EHu "$carto_user" make -j $(nproc) -C "$dst/posm-carto" project.xml
  sudo -EHu "$carto_user" make -j $(nproc) -C "$dst/posm-carto" smaller

  # create/update configuration entry
  expand etc/posm-carto.json /etc/tessera.conf.d/posm-carto.json

  # restart
  service tessera restart

  # register a cron job that reads diffs and updates the rendering database
  crontab -u $carto_user ${BOOTSTRAP_HOME}/etc/gis.crontab

  mkdir -p /opt/data/osm/expiry
  chown "$carto_user:$carto_user" /opt/data/osm
  chown "$carto_user:$carto_user" /opt/data/osm/expiry

  sudo -u $carto_user osmosis --read-replication-interval-init workingDirectory=/opt/data/osm
  sudo -u $carto_user sed -Ei 's!^baseUrl\s?=.*$!baseUrl=file:///opt/data/osm/replication/minute!' /opt/data/osm/configuration.txt
  sudo -u $carto_user sed -Ei 's!^maxInterval\s?=.*$!maxInterval=0!' /opt/data/osm/configuration.txt
}

deploy carto
