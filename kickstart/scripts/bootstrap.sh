#!/bin/sh

ks_fetch() {
  mkdir -p /root/`dirname "$1"`
	wget -q -O "/root/${1}" "$KS/${1}"
}

while getopts "k:s:x" opt; do
  case $opt in
    k)
      KS="$OPTARG"
      ;;
    s)
      set -a
      eval "$OPTARG"
      set +a
      ;;
    x)
      set -x
      ;;
  esac
done

err=0
ks_fetch "scripts/functions.sh" && . /root/scripts/functions.sh
for i in "$@"; do
  if ! ks_fetch "scripts/${i}_deploy.sh"; then
    err=1
    continue
  fi
  chmod +x /root/scripts/${i}_deploy.sh
  if ! /root/scripts/${i}_deploy.sh; then
    err=1
  fi
done

exit $err
