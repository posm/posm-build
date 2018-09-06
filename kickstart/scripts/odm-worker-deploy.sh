#!/bin/bash

deploy_worker_ubuntu() {
  # enable mDNS resolution
  apt install -y --no-install-recommends libnss-mdns

  expand usr/local/bin/register-nodeodm-worker.sh /usr/local/bin/register-nodeodm-worker.sh
  chmod +x /usr/local/bin/register-nodeodm-worker.sh

  ln -s /usr/local/bin/register-nodeodm-worker.sh /usr/lib/networkd-dispatcher/routable.d/
}

deploy worker
