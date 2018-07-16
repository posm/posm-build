#!/bin/bash

deploy_wifi_ubuntu() {
  apt-get install --no-install-recommends -y wireless-tools

  apt-get remove --purge -y \
    network-manager

  # disable IPv6
  expand etc/sysctl.d/50-disable_ipv6.conf /etc/sysctl.d/50-disable_ipv6.conf

  echo GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0\" > /etc/default/grub.d/99-posm.cfg

  service procps start

  apt-get install --no-install-recommends -y \
    dnsmasq \
    dnsmasq-utils \
    hostapd \
    iw \
    rfkill \
    rng-tools
}

deploy wifi
