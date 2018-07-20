#!/bin/bash

deploy_tl_ubuntu() {
  npm install --unsafe-perm -g mapnik@~3.7.2 @mapbox/mbtiles @mapbox/tilelive \
    @mapbox/tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource \
    tilelive-file tilelive-http tilelive-mapbox @mapbox/tilejson \
    @mapbox/tilelive-vector tilelive-blend tl
}

deploy tl
