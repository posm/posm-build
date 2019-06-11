#!/bin/bash

deploy_nodeodm_ubuntu() {
  docker pull opendronemap/node-opendronemap@${webodm_nodeodm_digest}

  expand etc/systemd/system/nodeodm.service.hbs /etc/systemd/system/nodeodm.service

  systemctl enable --now nodeodm
}

deploy nodeodm
