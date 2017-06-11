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

  expand etc/imagery-web.upstart /etc/init/imagery-web.conf
  expand etc/imagery-worker.upstart /etc/init/imagery-worker.conf

  service imagery-web start
  service imagery-worker start
}

deploy imagery
