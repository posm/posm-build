#!/bin/bash

deploy_virt_ubuntu() {
  apt-get install --no-install-recommends -y \
    virt-what

  local v="`virt-what 2>/dev/null`"
  if [ $? = 0 ] && [ -n "$v" ]; then
    apt-get install --no-install-recommends -y \
      linux-virtual-lts-xenial/ \
      open-vm-tools
  fi
}

deploy virt
