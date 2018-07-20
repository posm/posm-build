#!/bin/bash

deploy_base_ubuntu() {
  echo "System Info"
  lsb_release -a
  uname -a
  echo
  echo "CPU:"
  cat /proc/cpuinfo
  echo "Memory:"
  free -h
  echo
  echo "Disks:"
  fdisk -l
  df -h
  echo
  echo "Network:"
  ifconfig -a

  apt-get purge -y \
    lxd \
    lxd-client \
    whoopsie

  add-apt-repository universe

  apt-get -y upgrade
  apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    ssh \
    tmux \
    vim \
    moreutils \
    software-properties-common \
    apt-transport-https \
    virt-what \
    default-jre-headless

  # enable mDNS (posm.local)
  mkdir -p /etc/systemd/resolved.conf.d
  cat << EOF > /etc/systemd/resolved.conf.d/mdns.conf
[Resolve]
MulticastDNS=yes
EOF

  systemctl restart systemd-resolved

  curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq
  chmod +x /usr/local/bin/jq

  grep -q "^PermitRootLogin" /etc/ssh/sshd_config && sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  grep -q "^PasswordAuthentication" /etc/ssh/sshd_config && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  grep -q "^UseDNS" /etc/ssh/sshd_config || echo "UseDNS no" >> /etc/ssh/sshd_config

  service ssh restart
}

deploy base
