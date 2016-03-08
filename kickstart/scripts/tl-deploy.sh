#!/bin/bash

deploy_tl_ubuntu() {
  apt-get install --no-install-recommends -y nodejs sqlite3
  npm install -g tl
  local prefix=`npm prefix -g`

  # move mapnik up a level in the tree (virtual tree w/ npm@3, but still...)
  (cd $prefix/lib/node_modules/tl && find node_modules -type d -name mapnik -exec rm -rf {} \;)
  (cd $prefix/lib/node_modules/tl && npm install mapnik@3.5.2)

  # install useful modules for tile rendering
  (cd $prefix/lib/node_modules/tl && npm install mbtiles tilelive-http tilejson tilelive-mapnik tilelive-blend)
}

deploy tl
