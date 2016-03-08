#!/bin/sh

deploy_tessera_ubuntu() {
  apt-get install --no-install-recommends -y nodejs

  npm install -g tessera
  local prefix=`npm prefix -g`
  (cd $prefix/lib/node_modules/tessera && npm install mapnik@3.5.2 mbtiles tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector tilelive-blend)

  # configure
  mkdir -p /etc/tessera.conf.d
  expand etc/posm-carto.json /etc/tessera.conf.d/posm-carto.json
  expand etc/openstreetmap-carto.json /etc/tessera.conf.d/openstreetmap-carto.json

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart

  true
}

deploy tessera
