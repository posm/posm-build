#!/bin/bash

deploy_clusterodm_ubuntu() {
  docker pull opendronemap/clusterodm@${webodm_clusterodm_digest}

  expand etc/systemd/system/clusterodm.service.hbs /etc/systemd/system/clusterodm.service
  echo '[{"hostname":"nodeodm.service","port":"3001"}]' > /etc/clusterodm.json

  systemctl enable --now clusterodm
}

deploy clusterodm
