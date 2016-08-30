#!/bin/bash

deploy_docker_ubuntu() {
  apt install --no-install-recommends -y software-properties-common lsb-release apt-transport-https ca-certificates
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  add-apt-repository "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -c -s) main"
  apt update
  apt install --no-install-recommends -y \
    docker-engine \
    python-pip

  pip install docker-compose
}

deploy docker
