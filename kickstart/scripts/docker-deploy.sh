#!/bin/bash

deploy_docker_ubuntu() {
  apt install --no-install-recommends -y lsb-release apt-transport-https ca-certificates
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -c -s) stable"
  apt install --no-install-recommends -y \
    docker-ce \
    python-pip \
    python-setuptools \
    python-wheel

  pip install docker-compose
}

deploy docker
