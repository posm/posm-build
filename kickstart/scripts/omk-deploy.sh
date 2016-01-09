#!/bin/bash

dst=/opt/omk

deploy_omk_ubuntu() {
  # deps
  apt-get install -y \
    build-essential \
    python-pip

  # OMK user
  useradd -c 'OpenMapKit Server' -d "$dst" -m -r -s /bin/bash -U omk

  deploy_omk_server
}

deploy_omk_server() {
	# install OMK Server
  from_github "https://github.com/AmericanRedCross/OpenMapKitServer" "$dst/OpenMapKitServer"

  # fetch git submodules
  wget -q -O /root/sources/pyxform.tar.gz "https://github.com/spatialdev/pyxform/archive/e486b54d34d299d54049923e03ca5a6a1169af40.tar.gz"
  tar -zxf /root/sources/pyxform.tar.gz -C "$dst/OpenMapKitServer/odk/pyxform" --strip=1

  # use default settings
  cp $dst/OpenMapKitServer/settings.js.example $dst/OpenMapKitServer/settings.js

  # user / group omk should own this
  chown -R omk:omk "$dst/OpenMapKitServer"

  # install python packages for pyxform
  su - omk -c "cd \"$dst/OpenMapKitServer\" && pip install -r requirements.txt"
  
  # install node packages
  su - omk -c "cd \"$dst/OpenMapKitServer\" && npm install"

  # start
  expand etc/omk-server.upstart /etc/init/omk-server.conf
  start omk-server
}

deploy omk
