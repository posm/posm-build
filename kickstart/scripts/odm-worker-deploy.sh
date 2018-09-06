#!/bin/bash

deploy_worker_ubuntu() {
  # enable mDNS resolution
  apt install -y --no-install-recommends libnss-mdns

  expand usr/local/bin/register-nodeodm-worker.sh /usr/local/bin/register-nodeodm-worker.sh
  chmod +x /usr/local/bin/register-nodeodm-worker.sh

  expand etc/networkd-dispatcher/routable.d/register-nodeodm-worker.hbs /usr/lib/networkd-dispatcher/routable.d/
}

deploy worker
