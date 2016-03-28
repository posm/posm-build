#!/bin/bash

node_ver="${node_ver:-4}"

deploy_nodejs_ubuntu() {
  apt-get install --no-install-recommends -y software-properties-common apt-transport-https lsb-release
  wget -q -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  add-apt-repository -s "deb https://deb.nodesource.com/node_${node_ver}.x $(lsb_release -c -s) main"
  apt-get update
  apt-get install --no-install-recommends -y nodejs

  npm install -g interp
}

deploy nodejs
