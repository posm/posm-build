#!/bin/bash

deploy_wifi_ubuntu() {
  apt-get install --no-install-recommends -y linux-image-generic-lts-xenial wireless-tools

  apt-get remove --purge -y \
    network-manager

  # disable IPv6
  expand etc/sysctl.d/50-disable_ipv6.conf /etc/sysctl.d/50-disable_ipv6.conf

  service procps start

  apt-get install --no-install-recommends -y \
    dnsmasq \
    dnsmasq-utils \
    hostapd \
    iw \
    rfkill \
    rng-tools

  expand etc/hosts "/etc/hosts"

  # configure network interfaces
  expand etc/network/interfaces.d/usb0.cfg "/etc/network/interfaces.d/usb0.cfg"
  test "$posm_lan_netif" != "" && expand etc/network/interfaces.d/lan.cfg "/etc/network/interfaces.d/${posm_lan_netif}.cfg"
  test "$posm_wan_netif" != "" && expand etc/network/interfaces.d/wan.cfg "/etc/network/interfaces.d/${posm_wan_netif}.cfg"
  test "$posm_wlan_netif" != "" && expand etc/network/interfaces.d/wlan.cfg "/etc/network/interfaces.d/${posm_wlan_netif}.cfg"

  expand etc/hostapd.conf "/etc/hostapd/hostapd.conf"
  expand etc/dnsmasq-posm.conf "/etc/dnsmasq.d/50-posm.conf"
  expand etc/dnsmasq-default "/etc/default/dnsmasq"
}

deploy wifi
