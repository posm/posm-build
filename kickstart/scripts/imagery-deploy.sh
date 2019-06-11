#!/bin/bash

##
# Creates directories and configurations for the POSM Imagery API
# Nginx proxy configuration is done when deploying Nginx
#
# Depends:
#  * redis
##
deploy_imagery_ubuntu() {
  mkdir -p /opt/data/{imagery,uploads}

  chown posm-admin:posm-admin /opt/data/{imagery,uploads}

  docker pull quay.io/mojodna/posm-imagery-api

  expand etc/systemd/system/imagery-web.service.hbs /etc/systemd/system/imagery-web.service
  expand etc/systemd/system/imagery-worker.service.hbs /etc/systemd/system/imagery-worker.service

  systemctl enable --now imagery-web
  systemctl enable --now imagery-worker
}

deploy imagery
