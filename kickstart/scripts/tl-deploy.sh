#!/bin/bash

deploy_tl_ubuntu() {
  npm install -g tl
  local prefix=`npm prefix -g`

  # install useful modules for tile rendering
  (cd $prefix/lib/node_modules/tl && npm install mapnik mbtiles tilelive-http tilejson tilelive-mapnik tilelive-blend)
}

deploy tl
