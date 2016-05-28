#!/bin/bash

deploy_tl_ubuntu() {
  npm install -g mapnik mbtiles tilelive tilelive-mapnik tilelive-carto tilelive-tmstyle \
    tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector \
    tilelive-blend tl
}

deploy tl
