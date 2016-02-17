#!/bin/bash

carto_user="${carto_user:-${osm_carto_pg_owner:-gis}}"
carto_styles="${carto_styles:-mm osm}"
dst="/opt/$carto_user"

deploy_carto_ubuntu() {
  apt-get install nodejs -y
  useradd -c 'OSM/GIS User' -d "$dst" -m -r -s /bin/bash -U "$carto_user"
  echo -e "${osm_carto_pg_pass}\n${osm_carto_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$osm_carto_pg_owner'"
  su - postgres -c "createdb --owner='$osm_carto_pg_owner' '$osm_carto_pg_dbname'"
  su - postgres -c "psql --dbname='$osm_carto_pg_dbname' --command='CREATE EXTENSION postgis'"
  su - postgres -c "psql --dbname='$osm_carto_pg_dbname' --command='CREATE EXTENSION hstore'"
  local s
  for s in $carto_styles; do
    local fn="deploy_carto_$s"
    $fn
  done
}

deploy_carto_mm() {
  from_github "https://github.com/AmericanRedCross/posm-carto" "$dst/posm-carto"
  chown -R "$carto_user:$carto_user" "$dst/posm-carto"

  su - "$carto_user" -c "cd '$dst/posm-carto' && npm install --quiet"
  su - "$carto_user" -c "make -C '$dst/posm-carto' project.xml"

  rm -f "$dst/mm"
  ln -s posm-carto "$dst/mm"
}

deploy_carto_osm() {
  echo "openstreetmap-mapnik-carto-stylesheet-data openstreetmap-mapnik-carto-stylesheet-data/dloadcoastlines boolean true" | debconf-set-selections
  apt-get install -y \
    openstreetmap-mapnik-carto-stylesheet-data \
    fonts-droid fonts-khmeros fonts-khmeros-core fonts-sil-padauk fonts-sipa-arundina ttf-dejavu ttf-dejavu-core ttf-dejavu-extra ttf-indic-fonts-core ttf-kannada-fonts ttf-tamil-fonts ttf-unifont

  ln -s /etc/mapnik-osm-carto-data "$dst/osm"
}

deploy carto
