#!/bin/bash

deploy_hotspot_ubuntu() {
  local v="`virt-what 2>/dev/null`"
  if [ $? = 0 ] && [ -z "$v" ]; then
    # allow lo to use remote DNS servers (don't modify /etc/resolve.conf)
    grep -qe "^DNSMASQ_EXCEPT" /etc/default/dnsmasq || echo DNSMASQ_EXCEPT=\"lo\" >> /etc/default/dnsmasq

    expand etc/hosts "/etc/hosts"

    if [ -z "$posm_lan_netif" ]; then
      expand etc/systemd/network/lan.network.hbs /etc/systemd/network/lan.network
    fi
    expand etc/systemd/network/mac0.network.hbs /etc/systemd/network/mac0.network
    expand etc/systemd/network/wan.network.hbs /etc/systemd/network/wan.network
    expand etc/systemd/network/wlan.network.hbs /etc/systemd/network/wlan.network

    # we're managing networks fully ourselves
    rm -f /etc/netplan/50-cloud-init.yaml

    systemctl restart systemd-networkctl

    expand etc/hostapd.conf "/etc/hostapd/hostapd.conf"
    expand etc/dnsmasq-posm.conf "/etc/dnsmasq.d/50-posm.conf"

    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

    grep -qe "^DAEMON_CONF" /etc/default/hostapd || echo DAEMON_CONF=\"/etc/hostapd/hostapd.conf\" >> /etc/default/hostapd

    systemctl unmask hostapd.service
    systemctl enable hostapd.service
    systemctl start hostapd.service
    systemctl restart dnsmasq.service
  fi
}

deploy hotspot
