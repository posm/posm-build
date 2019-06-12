#!/bin/bash

deploy_worker_ubuntu() {
  # enable mDNS resolution
  apt install -y --no-install-recommends libnss-mdns

  expand usr/local/bin/register-nodeodm-worker.sh /usr/local/bin/register-nodeodm-worker.sh
  chmod +x /usr/local/bin/register-nodeodm-worker.sh

  mkdir -p /etc/networkd-dispatcher/configured.d
  expand etc/networkd-dispatcher/routable.d/register-nodeodm-worker /etc/networkd-dispatcher/configured.d/register-nodeodm-worker
  chmod +x /etc/networkd-dispatcher/configured.d/register-nodeodm-worker
}

deploy worker
