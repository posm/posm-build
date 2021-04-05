#!/bin/bash -e

cat /osm-sample.properties \
    | sed -e "s/{{OSM_PG_HOST}}/${OSM_PG_HOST}/" \
    | sed -e "s/{{OSM_DB}}/${OSM_DB}/" \
    | sed -e "s/{{OSM_USER}}/${OSM_USER}/" \
    | sed -e "s/{{OSM_PASSWORD}}/${OSM_PASSWORD}/" \
    > $OSMOSIS_INSTALL_DIR/osm.properties

exec "$@"
