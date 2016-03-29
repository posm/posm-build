#!/bin/bash

# Should use Ubuntu linux-image-3.19.0-42-generic
deploy_wifi_ubuntu() {
	apt-get install --no-install-recommends -y linux-image-3.19.0-42-generic linux-image-extra-3.19.0-42-generic linux-firmware wireless-tools

	ln -sf /lib/firmware/iwlwifi-7265D-12.ucode /lib/firmware/iwlwifi-3165-9.ucode
	ln -sf /lib/firmware/iwlwifi-7265-12.ucode /lib/firmware/iwlwifi-3165-12.ucode

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
