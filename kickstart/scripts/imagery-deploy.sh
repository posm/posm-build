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

  docker create \
    --dns ${posm_wlan_ip} \
    -e REDIS_URL="redis://redis" \
    -e SERVER_NAME="${posm_fqdn}" \
    -p 10000:8000 \
    --link redis \
    --name imagery-web \
    -u "$(id -u posm-admin):$(id -g posm-admin)" \
    -v /opt/data/imagery:/app/imagery \
    -v /opt/data/uploads:/app/uploads \
    quay.io/mojodna/posm-imagery-api

  docker create \
    --dns ${posm_wlan_ip} \
    --entrypoint celery \
    -e REDIS_URL="redis://redis" \
    -e SERVER_NAME="${posm_fqdn}" \
    --link redis \
    --name imagery-worker \
    -u "$(id -u posm-admin):$(id -g posm-admin)" \
    -v /opt/data/imagery:/app/imagery \
    -v /opt/data/uploads:/app/uploads \
    quay.io/mojodna/posm-imagery-api \
    worker -A app.celery --loglevel=info

  expand etc/imagery-web.upstart /etc/init/imagery-web.conf
  expand etc/imagery-worker.upstart /etc/init/imagery-worker.conf
}

deploy imagery
