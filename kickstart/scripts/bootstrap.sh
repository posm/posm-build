#!/bin/bash

ks_fetch() {
  if [ -n "$KS" ]; then
    mkdir -p /root/`dirname "$1"`
    wget -q -O "/root/${1}" "$KS/${1}"
  fi
  if [ -n "$2" ]; then
    cp -p "/root/${1}" "$2"
    return $?
  fi
  test -e "/root/$1"
  return $?
}

exec &> >(tee -a /root/bootstrap.log)
echo "[`date '+%c'`] Starting bootstrap: $0 $*"

# first pass
OPTSTRING="k:s:x"
while getopts "$OPTSTRING" opt; do
  case $opt in
    k)
      export KS="$OPTARG"
      ;;
    x)
      debug=1
      set -x
      ;;
  esac
done

err=0
ks_fetch "scripts/functions.sh" && . /root/scripts/functions.sh

for i in etc/settings etc/settings.local; do
  ks_fetch "$i"
  set -a
  test -e "/root/$i" && . "/root/$i"
  set +a
done
if [ -n "$debug" ] && [ "$debug" != 0 ]; then
  set -x
fi

# second pass (variables)
OPTIND=0
while getopts "$OPTSTRING" opt; do
  case $opt in
    s)
      set -a
      eval "$OPTARG"
      set +a
      ;;
  esac
done
shift $(expr $OPTIND - 1)

for i in "$@"; do
  if ! ks_fetch "scripts/${i}-deploy.sh"; then
    err=1
    continue
  fi
  chmod +x /root/scripts/${i}-deploy.sh
  echo "==> Deploying: $i"
  if ! . /root/scripts/${i}-deploy.sh; then
    err=1
  fi
done

exit $err
