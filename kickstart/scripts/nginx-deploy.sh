#!/bin/bash

dst=/opt/posm-www

deploy_nginx_ubuntu() {
  apt install --no-install-recommends -y nginx make apache2-utils
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
  git clone --recursive --depth 1 -b dist https://github.com/AmericanRedCross/OpenMapKitWebsite.git "$dst/openmapkit-website"
  git clone --recursive --depth 1 -b dist https://github.com/posm/posm-gcpi.git "$dst/posm-gcpi"

  expand etc/www/config.json /opt/posm-www/config.json

  apps=$(jq .apps /opt/posm-www/config.json)
  new_apps=$(cat << EOF | jq -s '.[0] + .[1] | unique'
$apps
[
  {
    "name": "ODM GCPs",
    "icon": "layout-skew-grid",
    "url": "//${posm_fqdn}/posm-gcpi/",
    "description": "OpenDroneMap Ground Control Points"
  }
]
EOF
)

  docs=$(jq .docs /opt/posm-www/config.json)
  new_docs=$(cat << EOF | jq -s '.[0] + .[1] | unique'
$docs
[
  {
    "name": "POSM Guide",
    "icon": "book",
    "url": "//${posm_fqdn}/guide/"
  },
  {
    "name": "About OMK",
    "icon": "book",
    "url": "//${posm_fqdn}/openmapkit-website/",
    "description": "About OpenMapKit"
  }
]
EOF
)

  config=$(jq . /opt/posm-www/config.json)
  cat << EOF | jq -s '.[0] * .[1]' > /opt/posm-www/config.json
$config
{
  "apps": $new_apps,
  "docs": $new_docs
}
EOF
}

deploy nginx
