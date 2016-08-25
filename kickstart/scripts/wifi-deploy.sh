#!/bin/bash

deploy_wifi_ubuntu() {
  apt-get install --no-install-recommends -y linux-image-generic-lts-xenial wireless-tools

  apt-get remove --purge -y \
    network-manager

  # disable IPv6
  expand etc/sysctl.d/50-disable_ipv6.conf

  service procps start

  apt-get install --no-install-recommends -y \
    dnsmasq \
    dnsmasq-utils \
    hostapd \
    iw \
    rfkill \
    rng-tools

  expand etc/hosts "/etc/hosts"
  expand etc/network-interfaces "/etc/network/interfaces"
  expand etc/hostapd.conf "/etc/hostapd/hostapd.conf"
  expand etc/dnsmasq-posm.conf "/etc/dnsmasq.d/50-posm.conf"
  expand etc/dnsmasq-default "/etc/default/dnsmasq"
}

deploy wifi
