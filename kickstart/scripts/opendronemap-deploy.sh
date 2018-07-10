#!/bin/bash

##
# Creates directories and configurations for the POSM OpenDroneMap API
# Nginx proxy configuration is done when deploying Nginx
#
# Depends:
#  * redis
##
deploy_opendronemap_ubuntu() {
  mkdir -p /opt/data/{opendronemap,uploads}

  chown posm-admin:posm-admin /opt/data/{opendronemap,uploads}

  docker pull quay.io/mojodna/posm-opendronemap-api

  expand etc/systemd/system/odm-web.service.hbs /etc/systemd/system/odm-web.service
  expand etc/systemd/system/odm-worker.service.hbs /etc/systemd/system/odm-worker.service

  systemctl enable odm-web
  systemctl enable odm-worker

  service odm-web start
  service odm-worker start
}

deploy opendronemap
