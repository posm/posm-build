#!/usr/bin/env bash

set -eo pipefail

PATH=/usr/local/bin:/usr/sbin:/usr/bin:/bin

# --rri will automatically fetch the latest state.txt; it will be initialized when osm2pgsql fully imports an extract
if [ -f /opt/data/osm/state.txt ]; then
  db=$(jq -r .osm_carto_pg_dbname /etc/posm.json)
  timestamp=$(date -u +\%Y\%m\%d-\%H\%M)
  # TODO use a named pipe
  expiry_file=/opt/data/osm/expiry/${timestamp}.txt

  osmosis \
    --read-replication-interval \
      workingDirectory=/opt/data/osm \
    --simplify-change \
    --write-xml-change - \
  2> /dev/null | \
    osm2pgsql \
      --append \
      --hstore-all \
      --hstore-add-index \
      --extra-attributes \
      --database $db \
      --slim \
      --expire-tiles "1-22" \
      --expire-output $expiry_file \
      -r osm \
      -

  if [ -s $expiry_file ]; then
    # restart if tiles would be expired
    sudo service tessera restart
  else
    # remove the expiry file
    rm -f $expiry_file
  fi
fi
