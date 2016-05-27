#!/bin/bash

dst=/opt/omk

deploy_omk_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    build-essential \
    default-jre-headless \
    python-pip \
    python-virtualenv

  # OMK user
  useradd -c 'OpenMapKit Server' -d "$dst" -m -r -s /bin/bash -U omk
  mkdir -p "$dst"
  chown omk:omk "$dst"
  cat - <<"EOF" >"$dst/.bashrc"
    # this is for interactive shell, not used by upstart!
    export PATH="$HOME/env/bin:$PATH"
EOF

  deploy_omk_server
}

deploy_omk_server() {
	# install OMK Server
  from_github "https://github.com/AmericanRedCross/OpenMapKitServer" "$dst/OpenMapKitServer"

  mkdir -p /root/sources

  # create backup directory
  mkdir -p /opt/data/backups/omk
  chown omk:omk /opt/data/backups/omk
  chmod 644 /opt/data/backups/omk

  # fetch pyxform submodule
  wget -q -O /root/sources/pyxform.tar.gz "https://github.com/spatialdev/pyxform/archive/e486b54d34d299d54049923e03ca5a6a1169af40.tar.gz"
  tar -zxf /root/sources/pyxform.tar.gz -C "$dst/OpenMapKitServer/api/odk/pyxform" --strip=1

  # user / group omk should own this
  chown -R omk:omk "$dst/OpenMapKitServer"
  
  # allow posm-admin and others to write forms
  chmod -R a+rwx "$dst/OpenMapKitServer/data/forms"
  
  # setup python virtualenv
  su - omk -c "virtualenv --system-site-packages '$dst/env'"
  # install python packages for pyxform
  su - omk -c "env PATH='$dst/env/bin:$PATH' pip install -r '$dst/OpenMapKitServer/requirements.txt'"

  # install node packages
  su - omk -c "cd \"$dst/OpenMapKitServer\" && npm install"

  # start
  expand etc/omk-server.upstart /etc/init/omk-server.conf
  service omk-server restart

  true
}

deploy omk
