#!/bin/bash

deploy_bridge_ubuntu() {
  local v="`virt-what 2>/dev/null`"
  if [ $? = 0 ] && [ -z "$v" ]; then
		# enable port forwarding
		expand etc/sysctl.d/99-forwarding.conf /etc/sysctl.d/99-forwarding.conf

		# reload sysctl settings
		systemctl restart systemd-sysctl

		# configure interface hook scripts
		mkdir -p /etc/networkd-dispatcher/{routable,off}.d
		expand etc/enable-port-forwarding /etc/networkd-dispatcher/routable.d/enable_port_forwarding
		expand etc/disable-port-forwarding /etc/networkd-dispatcher/off.d/disable_port_forwarding
		chmod +x /etc/networkd-dispatcher/routable.d/enable_port_forwarding
		chmod +x /etc/networkd-dispatcher/off.d/disable_port_forwarding

		IFACE=$posm_wan_netif /etc/networkd-dispatcher/routable.d/enable_port_forwarding

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
