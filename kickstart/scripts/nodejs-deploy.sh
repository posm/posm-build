#!/bin/sh

deploy_nodejs_ubuntu() {
  wget -q -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  echo -e 'deb https://deb.nodesource.com/node_4.x trusty main\ndeb-src https://deb.nodesource.com/node_4.x trusty main' > /etc/apt/sources.list.d/nodesource.list
  apt-get install nodejs -y
}

deploy nodejs
