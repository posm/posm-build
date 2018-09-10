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
    expand etc/systemd/network/wan.network.hbs /etc/systemd/network/10-wan.network
    expand etc/systemd/network/wan-static.network.hbs /etc/systemd/network/20-wan-static.network
    expand etc/systemd/network/wlan.network.hbs /etc/systemd/network/wlan.network

    mkdir -p /usr/lib/networkd-dispatcher/configuring.d
    expand etc/networkd-dispatcher/configuring.d/enable-wan-timeout.hbs /usr/lib/networkd-dispatcher/configuring.d/enable-wan-timeout
    chmod +x /usr/lib/networkd-dispatcher/configuring.d/enable-wan-timeout

    expand etc/systemd/system/wan-timeout.service.hbs /etc/systemd/system/wan-timeout.service
    expand etc/systemd/system/wan-timeout.timer /etc/systemd/system/wan-timeout.timer

    # we're managing networks fully ourselves
    rm -f /etc/netplan/50-cloud-init.yaml

    systemctl restart systemd-networkd

    # configure hostapd / dnsmasq if appropriate
    if [ -f /etc/hostapd/hostapd.conf ]; then
      expand etc/hostapd.conf "/etc/hostapd/hostapd.conf"
      expand etc/dnsmasq-posm.conf "/etc/dnsmasq.d/50-posm.conf"

      ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

      grep -qe "^DAEMON_CONF" /etc/default/hostapd || echo DAEMON_CONF=\"/etc/hostapd/hostapd.conf\" >> /etc/default/hostapd

      systemctl unmask hostapd.service
      systemctl enable hostapd.service
      systemctl start hostapd.service
      systemctl restart dnsmasq.service
    fi

    # reconfigure samba if installed
    if [ -f /etc/samba/smb.conf ]; then
      # rewrite Samba config to include active interfaces
      expand etc/smb.conf /etc/samba/smb.conf
      service smbd restart
    fi
  else
    # configure the VM's WAN interface
    expand etc/systemd/network/wan.network.hbs /etc/systemd/network/10-wan.network

    systemctl restart systemd-networkd
  fi
}

deploy hotspot
