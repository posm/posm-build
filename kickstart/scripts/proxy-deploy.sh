#!/bin/bash

deploy_proxy_ubuntu() {
  apt-get install --no-install-recommends -y polipo

  expand etc/polipo/config /etc/polipo/config
  expand etc/dnsmasq-00proxy.conf /etc/dnsmasq.d/00-proxy.conf

  service polipo restart
  service dnsmasq restart
}

deploy proxy
