#!/bin/sh

deploy_tessera_ubuntu() {
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  apt-get update
  apt-get install -y libstdc++6

  npm install -g mapnik@~3.5.14 mbtiles tilelive tilelive-mapnik tilelive-carto tilelive-tmstyle \
    tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector \
    tilelive-blend tessera

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart
}

deploy tessera
