#!/bin/bash

node_ver="${node_ver:-5}"

deploy_nodejs_ubuntu() {
  wget -q -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  echo -e "deb https://deb.nodesource.com/node_${node_ver}.x trusty main\ndeb-src https://deb.nodesource.com/node_${node_ver}.x trusty main" > /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install --no-install-recommends -y nodejs

  npm install -g npm@~3.3.12

  npm install -g interp
}

deploy nodejs
