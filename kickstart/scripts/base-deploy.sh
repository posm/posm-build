#!/bin/bash

deploy_base_ubuntu() {
  apt-get install -y \
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
