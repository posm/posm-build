#!/bin/bash

deploy_mbtiles_ubuntu() {
  apt-get install nodejs -y
  apt-get install sqlite3 -y
  npm install -g tl
  local prefix=`npm prefix -g`

  # move mapnik up a level in the tree (virtual tree w/ npm@3, but still...)
  (cd $prefix/lib/node_modules/tl && find node_modules -type d -name mapnik -exec rm -rf {} \;)
  (cd $prefix/lib/node_modules/tl && npm install mapnik)

  # install useful modules for tile rendering
  (cd $prefix/lib/node_modules/tl && npm install mbtiles tilelive-http tilejson tilelive-mapnik tilelive-blend)
}

deploy mbtiles
