#!/bin/sh

deploy_tessera_ubuntu() {

  npm install -g mapnik mbtiles tilelive tilelive-mapnik tilelive-carto tilelive-tmstyle \
    tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector \
    tilelive-blend tessera

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart
}

deploy tessera
