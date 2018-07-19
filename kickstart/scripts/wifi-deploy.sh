#!/bin/bash

deploy_wifi_ubuntu() {
  systemctl stop systemd-resolved

  apt-get install --no-install-recommends -y \
    dnsmasq \
    dnsmasq-utils \
    hostapd \
    iw \
    rfkill \
    rng-tools \
    wireless-tools

  systemctl start systemd-resolved
}

deploy wifi
