#!/bin/sh

deploy_tessera_ubuntu() {
  apt-get install --no-install-recommends -y nodejs

  npm install -g tessera
  local prefix=`npm prefix -g`
  # move mapnik up a level in the tree (virtual tree w/ npm@3, but still...)
  (cd $prefix/lib/node_modules/tessera && find node_modules -type d -name mapnik -exec rm -rf {} \;)
  (cd $prefix/lib/node_modules/tessera && npm install mapnik mbtiles tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector tilelive-blend)

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart
}

deploy tessera
