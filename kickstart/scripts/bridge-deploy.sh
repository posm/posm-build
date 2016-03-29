#!/bin/bash

deploy_bridge_ubuntu() {
	# enable port forwarding
	expand etc/sysctl.d/99-forwarding.conf /etc/sysctl.d/99-forwarding.conf

	sysctl -p

	# configure interface hook scripts
	expand etc/enable-port-forwarding /etc/network/if-up.d/enable_port_forwarding
	expand etc/disable-port-forwarding /etc/network/if-down.d/disable_port_forwarding
	chmod +x /etc/network/if-up.d/enable_port_forwarding
	chmod +x /etc/network/if-down.d/disable_port_forwarding

	service networking restart

	# disable DNS wildcarding

	rm /etc/dnsmasq.d/99-captive.conf

	service dnsmasq restart

	# disable Nginx captive portal

	rm -f /etc/nginx/sites-enabled/
}

deploy bridge
