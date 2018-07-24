#!/bin/bash

deploy_bridge_ubuntu() {
  local v="`virt-what 2>/dev/null`"
  if [ $? = 0 ] && [ -z "$v" ]; then
    # enable port forwarding
    expand etc/sysctl.d/99-forwarding.conf /etc/sysctl.d/99-forwarding.conf

    # reload sysctl settings
    systemctl restart systemd-sysctl

    # configure interface hook scripts
    expand etc/networkd-dispatcher/routable.d/enable-port-forwarding.hbs /usr/lib/networkd-dispatcher/routable.d/enable-port-forwarding
    expand etc/networkd-dispatcher/no-carrier.d/disable-port-forwarding.hbs /usr/lib/networkd-dispatcher/no-carrier.d/disable-port-forwarding
    chmod +x /usr/lib/networkd-dispatcher/routable.d/enable-port-forwarding
    chmod +x /usr/lib/networkd-dispatcher/no-carrier.d/disable-port-forwarding

    IFACE=$posm_wan_netif /usr/lib/networkd-dispatcher/routable.d/enable-port-forwarding

    # disable DNS wildcarding

    rm -r /etc/dnsmasq.d/99-captive.conf

    service dnsmasq restart

    # disable Nginx captive portal

    rm -f /etc/nginx/sites-enabled/captive

    service nginx restart

    posm_network_bridged=1 expand etc/posm.json /etc/posm.json
  fi
}

deploy bridge
