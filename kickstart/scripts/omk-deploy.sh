#!/bin/bash

dst=/opt/omk

deploy_omk_ubuntu() {
  # deps
  apt-get install -y \
    build-essential

  # FP user & env
  useradd -c 'OpenMapKit Server' -d "$dst" -m -r -s /bin/bash -U omk
  cat - <<"EOF" >"$dst/.bashrc"
    for d in "$HOME" "$HOME"/fp-*; do
      if [ -e "$d/bin" ]; then
        PATH="$PATH:$d/bin"
      fi
      if [ -e "$d/.env" ]; then
        set -a
        . "$d/.env"
        set +a
      fi
    done
EOF

  deploy_omk_server
}

deploy_omk_server() {
	# install OMK Server
  from_github "https://github.com/AmericanRedCross/OpenMapKitServer" "$dst/OpenMapKitServer"
  cp $dst/OpenMapKitServer/settings.js.example $dst/OpenMapKitServer/settings.js
  chown -R omk:omk "$dst/OpenMapKitServer"

  su - omk -c "cd \"$dst/OpenMapKitServer\" && npm install"

  echo "==> Start OpenMapKit Server with: sudo su - omk -c \"cd OpenMapKitServer && npm start\""
}

deploy omk
