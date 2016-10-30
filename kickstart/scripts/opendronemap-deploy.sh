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

  docker create \
    --dns ${posm_wlan_ip} \
    -e REDIS_URL="redis://redis" \
    -e SERVER_NAME="${posm_fqdn}" \
    -p 10001:8000 \
    --link redis \
    --name odm-web \
    -u "$(id -u posm-admin):$(id -g posm-admin)" \
    -v /opt/data/opendronemap:/app/projects \
    -v /opt/data/uploads:/app/uploads \
    quay.io/mojodna/posm-opendronemap-api

  docker create \
    --dns ${posm_wlan_ip} \
    --entrypoint celery \
    -e REDIS_URL="redis://redis" \
    -e SERVER_NAME="${posm_fqdn}" \
    --link redis \
    --name odm-worker \
    -u "$(id -u posm-admin):$(id -g posm-admin)" \
    -v /opt/data/opendronemap:/app/projects \
    -v /opt/data/uploads:/app/uploads \
    quay.io/mojodna/posm-opendronemap-api \
    worker -A app.celery --loglevel=info --concurrency=1

  expand etc/odm-web.upstart /etc/init/odm-web.conf
  expand etc/odm-worker.upstart /etc/init/odm-worker.conf
}

deploy opendronemap
