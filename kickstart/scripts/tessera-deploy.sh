#!/bin/sh

deploy_tessera_ubuntu() {
  apt-get install --no-install-recommends -y nodejs

  npm install -g tessera
  local prefix=`npm prefix -g`
  (cd $prefix/lib/node_modules/tessera && npm install mbtiles tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector tilelive-blend)

  # configure
  expand etc/tessera.conf /etc/tessera.conf.json

  expand etc/tessera.upstart /etc/init/tessera.conf
  echo 'manual' > /etc/init/tessera.override
}

deploy tessera
