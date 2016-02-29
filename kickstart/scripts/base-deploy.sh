#!/bin/bash

deploy_base_ubuntu() {
  apt-get purge -y \
    whoopsie

  apt-get update
  apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
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
