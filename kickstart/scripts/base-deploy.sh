#!/bin/bash

deploy_base_ubuntu() {
  apt-get purge -y \
    whoopsie

  apt-get update
  apt-get install --no-install-recommends -y \
    avahi-daemon \
    ca-certificates \
    curl \
    git \
    jq \
    ssh \
    vim
}

deploy_base_rhel() {
  yum install -y \
    curl \
    git \
    openssh \
    vim-enhanced
}

deploy base
