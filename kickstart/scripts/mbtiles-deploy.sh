#!/bin/bash

deploy_mbtiles_ubuntu() {
  apt-get install nodejs -y
  apt-get install sqlite3 -y
  npm install -g tl
  local prefix=`npm prefix -g`
  (cd $prefix/lib/node_modules/tl && npm install mbtiles tilelive-http)
}

deploy mbtiles
