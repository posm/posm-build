#!/bin/bash

deploy_tl_ubuntu() {
  npm install -g tl
  local prefix=`npm prefix -g`

  # install useful modules for tile rendering
  (cd $prefix/lib/node_modules/tl && npm install mbtiles tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource tilelive-file tilelive-http tilelive-mapbox tilejson tilelive-vector tilelive-blend)
  # move mapnik up a level in the tree (virtual tree w/ npm@3, but still...)
  (cd $prefix/lib/node_modules/tl && find node_modules -type d -name mapnik -exec rm -rf {} \;)
  (cd $prefix/lib/node_modules/tl && npm install mapnik)
}

deploy tl
