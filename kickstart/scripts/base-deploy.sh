#!/bin/bash

deploy_base_ubuntu() {
  apt-get purge -y \
    whoopsie

  apt-get update
  apt-get -y upgrade
  apt-get install --no-install-recommends -y \
    avahi-daemon \
    avahi-autoipd \
    ca-certificates \
    curl \
    git \
    ssh \
    tmux \
    vim \
    moreutils \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    virt-what \
    default-jre-headless \
    libnss-mdns \
    postfix

  # configure postfix
  expand etc/postfix/main.cf /etc/postfix/main.cf

  curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq
  chmod +x /usr/local/bin/jq

  sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  grep -q "UseDNS" /etc/ssh/sshd_config || echo "UseDNS no" >> /etc/ssh/sshd_config
}

deploy base
