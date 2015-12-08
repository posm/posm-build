#!/bin/sh

ks_fetch() {
  mkdir -p /root/`dirname "$1"`
	wget -q -O "/root/${1}" "$KS/${1}"
}

from_github() {
  local url="$1"
  local dst="$2"
  mkdir -p "$dst"
  curl --silent --location "$url/archive/master.tar.gz" | tar -zxf - -C "$dst" --strip=1
  chown -R root:root "$dst"
  chmod -R o-w "$dst"
}

deploy() {
  export DEBIAN_FRONTEND=noninteractive

  vendor=`lsb_release -si 2>/dev/null`
  if [ -z "$vendor" ]; then
    if [ -e /etc/redhat-release ]; then
      vendor=`awk '{print $1}' /etc/redhat-release`
    fi
  fi

  case $vendor in
    Ubuntu)
      fn="deploy_${1}_ubuntu"
      ;;
    CentOS|Red*)
      fn="deploy_${1}_rhel"
      ;;
    *)
      ;;
  esac
  if [ x"$(type -t $fn)" != x"function" ]; then
    fn="deploy_${1}"
  fi
  $fn
}
