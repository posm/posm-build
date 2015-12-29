#!/bin/bash

deploy_virt_ubuntu() {
  apt-get install -qq -y \
    virt-what

  local v="`virt-what 2>/dev/null`"
  if [ $? = 0 ] && [ -n "$v" ]; then
    apt-get install -y \
      linux-virtual \
      open-vm-tools
  fi
}

deploy virt
