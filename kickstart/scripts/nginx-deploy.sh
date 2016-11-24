#!/bin/bash

dst=/opt/posm-www

deploy_nginx_ubuntu() {
  apt-get install --no-install-recommends -y nginx make
  expand etc/nginx-posm.conf /etc/nginx/sites-available/posm
  rm -f /etc/nginx/sites-enabled/default
  ln -sf ../sites-available/posm /etc/nginx/sites-enabled/00-posm
  service nginx restart

  mkdir -p "$dst"
  chmod 755 "$dst"

  git clone --recursive --depth 1 https://github.com/AmericanRedCross/posm-local-home "$dst"

  # fetch software to be bundled
  make -C "$dst"

  sed -i -e "s/osm.posm.io/${osm_fqdn}/" "$dst/index.html"
}

deploy nginx
