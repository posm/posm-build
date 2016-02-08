#!/bin/bash

dst=/opt/posm-www/id

deploy_id_ubuntu() {
  # deps
  apt-get install -y \
    build-essential

  # create user
  useradd -c 'OSM iD' -d "$dst" -m -r -s /bin/bash -U id

  # install
  from_github "https://github.com/AmericanRedCross/iD" "$dst" "posm"
  chown -R id:id "$dst"

  # patch hostname
  sed -i -e "s/posm\.local/${posm_hostname}/g" "$dst/index.html"

  # "build"
  su - id -c "make -C '$dst'"
}

deploy id
