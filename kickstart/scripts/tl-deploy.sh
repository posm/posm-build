#!/bin/bash

deploy_tl_ubuntu() {
  apt-get install --no-install-recommends -y nodejs sqlite3
  npm install -g tl
  local prefix=`npm prefix -g`

  # install useful modules for tile rendering
  (cd $prefix/lib/node_modules/tl && npm install mapnik mbtiles tilelive-http tilejson tilelive-mapnik tilelive-blend)
}

deploy tl
