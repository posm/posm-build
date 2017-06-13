#!/bin/bash

dst=/opt/posm-www

deploy_nginx_ubuntu() {
  apt-get install --no-install-recommends -y nginx make apache2-utils
  expand etc/nginx-posm.conf /etc/nginx/sites-available/posm
  rm -f /etc/nginx/sites-enabled/default
  ln -sf ../sites-available/posm /etc/nginx/sites-enabled/00-posm

  # make auth credentials available in case auth is enabled
  htpasswd -bc /etc/nginx/htpasswd $auth_user $auth_password

  service nginx restart

  mkdir -p "$dst"
  chmod 755 "$dst"

  git clone --recursive --depth 1 -b dist https://github.com/posm/posm-admin-ui "$dst"
  git clone --recursive --depth 1 -b guide https://github.com/posm/posm.github.io "$dst/guide"

  expand etc/www/config.json /opt/posm-www/config.json
}

deploy nginx
