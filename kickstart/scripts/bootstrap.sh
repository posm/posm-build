#!/bin/sh

ks_fetch() {
  if [ -n "$KS" ]; then
    mkdir -p /root/`dirname "$1"`
    wget -q -O "/root/${1}" "$KS/${1}"
  fi
}

while getopts "k:s:x" opt; do
  case $opt in
    k)
      export KS="$OPTARG"
      ;;
    s)
      set -a
      eval "$OPTARG"
      set +a
      ;;
    x)
      debug=1
      set -x
      ;;
  esac
done
shift $(expr $OPTIND - 1)

err=0
ks_fetch "scripts/functions.sh" && . /root/scripts/functions.sh
for i in "$@"; do
  if ! ks_fetch "scripts/${i}-deploy.sh"; then
    err=1
    continue
  fi
  chmod +x /root/scripts/${i}-deploy.sh
  if ! . /root/scripts/${i}-deploy.sh; then
    err=1
  fi
done

exit $err
