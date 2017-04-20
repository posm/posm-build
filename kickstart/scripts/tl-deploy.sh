#!/bin/bash

deploy_tl_ubuntu() {
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  apt-get update
  apt-get install -y libstdc++6

  npm install -g mapnik@~3.5.14 mbtiles tilelive tilelive-mapnik tilelive-carto tilelive-tmstyle \
    tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector \
    tilelive-blend tl
}

deploy tl
