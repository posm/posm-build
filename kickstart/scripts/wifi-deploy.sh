#!/bin/bash

deploy_wifi_ubuntu() {

  apt-get install --no-install-recommends -y \
    dnsmasq \
    dnsmasq-utils \
    hostapd \
    iw \
    rfkill \
    rng-tools \
    wireless-tools

  systemctl stop systemd-resolved
  systemctl restart dnsmasq
  systemctl start systemd-resolved
}

deploy wifi
