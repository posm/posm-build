#!/bin/bash

deploy_tl_ubuntu() {
  npm install --unsafe-perm -g \
    mapnik@~3.7.2 \
    @mapbox/mbtiles@~0.10.0 \
    @mapbox/tilelive@~6.0.0 \
    @mapbox/tilelive-mapnik@~1.0.0 \
    tilelive-carto@~0.8.0 \
    tilelive-tmstyle@~0.8.0 \
    tilelive-tmsource@~0.8.2 \
    tilelive-file@~0.0.3 \
    tilelive-http@~0.14.0 \
    tilelive-mapbox@~0.5.0 \
    @mapbox/tilejson@~1.1.0 \
    @mapbox/tilelive-vector@~4.2.0 \
    tilelive-blend@~0.5.1 \
    tl@~0.10.2
}

deploy tl
