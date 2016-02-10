#!/bin/bash

dst=/opt/posm-www/id

deploy_id_ubuntu() {
  # deps
  apt-get install -y \
    build-essential

  # install
  from_github "https://github.com/AmericanRedCross/iD" "$dst" "posm"
  chown -R posm:posm "$dst"

  # patch hostname
  sed -i -e "s/posm\.local/${posm_hostname}/g" "$dst/index.html"

  # "build"
  su - posm -c "make -C '$dst'"
  chown -R nobody:nogroup "$dst"
}

deploy id
