#!/bin/bash

dst=/opt/omk

deploy_omk_ubuntu() {
  # deps
  apt-get install -y \
    build-essential

  # OMK user
  useradd -c 'OpenMapKit Server' -d "$dst" -m -r -s /bin/bash -U omk

  deploy_omk_server
}

deploy_omk_server() {
	# install OMK Server
  from_github "https://github.com/AmericanRedCross/OpenMapKitServer" "$dst/OpenMapKitServer"
  cp $dst/OpenMapKitServer/settings.js.example $dst/OpenMapKitServer/settings.js
  chown -R omk:omk "$dst/OpenMapKitServer"

  su - omk -c "cd \"$dst/OpenMapKitServer\" && npm install"

  # start
  expand etc/omk-server.upstart /etc/init/omk-server.conf
  start omk-server
}

deploy omk
