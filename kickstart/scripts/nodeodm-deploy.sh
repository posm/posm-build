#!/bin/bash

deploy_webodm_ubuntu() {
  docker pull opendronemap/node-opendronemap

  expand etc/systemd/system/nodeodm.service.hbs /etc/systemd/system/nodeodm.service

  systemctl enable nodeodm

  service nodeodm start
}

deploy webodm
