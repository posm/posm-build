#!/bin/bash

demo_data_pbf="${demo_data_pbf:-http://download.geofabrik.de/north-america/us/colorado-latest.osm.pbf}"
osm_pg_dbname="${osm_pg_dbname:-gis}"
osm_pg_owner="${osm_pg_owner:-gis}"
pgsql_ver="${pgsql_ver:-9.3}"
postgis_ver="${postgis_ver:-2.1}"
osm_pg_users="${osm_pg_users:-}"

dst="/opt/$osm_pg_owner"

deploy_demo_data_ubuntu() {
  apt-get install -y \
    fonts-droid fonts-khmeros fonts-khmeros-core fonts-sil-padauk fonts-sipa-arundina ttf-dejavu ttf-dejavu-core ttf-dejavu-extra ttf-indic-fonts-core ttf-kannada-fonts ttf-tamil-fonts ttf-unifont
  apt-get install -y \
    "postgresql-$pgsql_ver-postgis-$postgis_ver"

  useradd -c 'OSM/GIS User' -d "$dst" -m -r -s /bin/bash -U "$osm_pg_owner"

  export DEBIAN_FRONTEND=noninteractive
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/initdb boolean false"
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/grant_user string $osm_pg_owner"
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/dbname string $osm_pg_dbname"
  apt-get install -y \
    openstreetmap-postgis-db-setup

  env DBOWNER="$osm_pg_owner" DBNAME="$osm_pg_dbname" /usr/bin/install-postgis-osm-db.sh
  local u
  for u in $osm_pg_users; do
    (cd /tmp; /usr/bin/install-postgis-osm-user.sh "$osm_pg_dbname" "$u")
  done

  local mem=`vmstat | awk 'NR == 3 { print int($4/1024) }'`
  local cpu=`grep -c rocessor /proc/cpuinfo`
  local pbf="${TMPDIR:-/tmp}/demo_data.pbf"
  wget -q -O "$pbf" "$demo_data_pbf"

  su - "$osm_pg_owner" -c "osm2pgsql --slim -C $mem --number-processes $cpu '$pbf'"
}

deploy demo_data
