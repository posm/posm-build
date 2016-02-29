#!/bin/bash

dst=/opt/posm-www/id

deploy_id_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    build-essential

  # install
  from_github "https://github.com/AmericanRedCross/iD" "$dst" "posm"
  chown -R posm:posm "$dst"

  # patch hostname
  sed -i -e "s/posm\.local/${posm_hostname}/g" "$dst/index.html"

  # patch credentials
  sed -i -e "s/5A043yRSEugj4DJ5TljuapfnrflWDte8jTOcWLlT/${posm_id_key}/g" "$dst/index.html"
  sed -i -e "s/aB3jKq1TRsCOUrfOIZ6oQMEDmv2ptV76PA54NGLL/${posm_id_secret}/g" "$dst/index.html"

  # "build"
  su - posm -c "make -C '$dst'"
  chown -R nobody:nogroup "$dst"
}

deploy id
