#!/bin/bash

deploy_webodm_ubuntu() {
  docker pull opendronemap/node-opendronemap@sha256:3b8f2d6183e4e2a7b682c9c2f741ff2b6fc4d82dc2deb63ab608ba820d3659df

  expand etc/systemd/system/nodeodm.service.hbs /etc/systemd/system/nodeodm.service

  systemctl enable nodeodm

  service nodeodm start
}

deploy webodm
