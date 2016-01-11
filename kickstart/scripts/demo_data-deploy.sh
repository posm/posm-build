#!/bin/bash

demo_data_pbf="${demo_data_pbf:-http://download.geofabrik.de/north-america/us/colorado-latest.osm.pbf}"
osm_pg_dbname="${osm_pg_dbname:-gis}"
osm_pg_owner="${osm_pg_owner:-gis}"
pgsql_ver="${pgsql_ver:-9.3}"
postgis_ver="${postgis_ver:-2.1}"
osm_pg_users="${osm_pg_users:-}"
osm2pg_style="${osm2pg_style:-}"
osm2pg_opt="${osm2pg_opt:---create --hstore-all --hstore-add-index --extra-attributes --slim --drop --unlogged}"
map_style="${map_style:-}"

dst="/opt/$osm_pg_owner"

deploy_demo_data_ubuntu() {
  apt-get install -y \
    fonts-droid fonts-khmeros fonts-khmeros-core fonts-sil-padauk fonts-sipa-arundina ttf-dejavu ttf-dejavu-core ttf-dejavu-extra ttf-indic-fonts-core ttf-kannada-fonts ttf-tamil-fonts ttf-unifont
  apt-get install -y \
    "postgresql-$pgsql_ver-postgis-$postgis_ver"

  useradd -c 'OSM/GIS User' -d "$dst" -m -r -s /bin/bash -U "$osm_pg_owner"

  export DEBIAN_FRONTEND=noninteractive
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/initdb boolean false" | debconf-set-selections
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/grant_user string $osm_pg_owner" | debconf-set-selections
  echo "openstreetmap-postgis-db-setup openstreetmap-postgis-db-setup/dbname string $osm_pg_dbname" | debconf-set-selections
  apt-get install -y \
    openstreetmap-postgis-db-setup mapnik-utils

  echo "openstreetmap-mapnik-carto-stylesheet-data openstreetmap-mapnik-carto-stylesheet-data/dloadcoastlines boolean true" | debconf-set-selections
  apt-get install -y \
    openstreetmap-mapnik-carto-stylesheet-data

  env DBOWNER="$osm_pg_owner" DBNAME="$osm_pg_dbname" /usr/bin/install-postgis-osm-db.sh

  #local mem=`vmstat | awk 'NR == 3 { print int($4/1024) }'`
  local mem=`awk 'NR == 1 { print int($2*.9/1024) } ' /proc/meminfo`
  if [ "$mem" -lt 3600 ]; then
    mem=""
  fi
  local cpu=`grep -c rocessor /proc/cpuinfo`
  local pbf="${TMPDIR:-/tmp}/demo_data.pbf"
  wget -q -O "$pbf" "$demo_data_pbf"

  case "$osm2pg_style" in
    *://*)
      wget -q -O "$dst/${osm2pg_style##*/}" "$osm2pg_style"
      osm2pg_style="$dst/${osm2pg_style##*/}"
      ;;
  esac

  su - "$osm_pg_owner" -c "osm2pgsql ${osm2pg_opt} ${osm2pg_style:+--style="$osm2pg_style"} --database='${osm_pg_dbname}' ${mem:+-C $mem} --number-processes $cpu '$pbf'"
  (cd /tmp; /usr/bin/install-postgis-osm-user.sh "$osm_pg_dbname" "$osm_pg_users")

  case "$map_style" in
    *://*)
      wget -q -O "$dst/${map_style##*/}" "$map_style"
      map_style="$dst/${map_style##*/}"
      ;;
  esac

  rm /etc/init/tessera.override
  start tessera

  # http://localhost:8082/#15/-0.1725/-78.4870
  #wget "http://localhost${tessera_port:+:$tessera_port}/15/9240/16400.png"
}

deploy demo_data
