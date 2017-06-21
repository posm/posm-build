#!/bin/bash

node_ver="${node_ver:-6}"

deploy_nodejs_ubuntu() {
  wget -q -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  echo "deb https://deb.nodesource.com/node_${node_ver}.x $(lsb_release -c -s) main" > /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install --no-install-recommends -y nodejs

  npm install -g interp
}

deploy nodejs
