#!/bin/bash

deploy_worker_ubuntu() {
  # enable mDNS resolution
  apt install -y --no-install-recommends libnss-mdns

  expand usr/local/bin/register-nodeodm-worker.sh /usr/local/bin/register-nodeodm-worker.sh
  chmod +x /usr/local/bin/register-nodeodm-worker.sh

  mkdir -p /etc/systemd/system/nodeodm.service.d
  expand etc/systemd/system/nodeodm.service.d/override.conf /etc/systemd/system/nodeodm.service.d/override.conf
}

deploy worker
