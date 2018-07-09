#!/bin/bash

if [ -z "$BOOTSTRAP_HOME" ]; then
  BOOTSTRAP_HOME="$(dirname "$0")"
  export BOOTSTRAP_HOME="$(dirname "$BOOTSTRAP_HOME")"
fi

ks_fetch() {
  if [ -n "$KS" ]; then
    mkdir -p "${BOOTSTRAP_HOME}/`dirname "$1"`"
    wget -q -O "${BOOTSTRAP_HOME}/${1}" "$KS/${1}"
  fi
  if [ -n "$2" ]; then
    cp -p "${BOOTSTRAP_HOME}/${1}" "$2"
    return $?
  fi
  test -e "${BOOTSTRAP_HOME}/$1"
  return $?
}

usage() {
  cat - <<EOF
usage: $0 [options] component1 ... componentN

  options:
    -n           dry-run
    -f           delay bootstrap execution until firstboot
    -k URL       kickstart server url (for settings and component scripts)
    -r           reboot when done
    -s VAR=val   override a setting variable
    -x           turn on debug (bash -x)

  Additional configuration can be achieved through:
    etc/settings
    etc/settings.local
EOF
  exit 64
}

bootstrap_firstboot() {
  local opt
  printf -v opt " %q" "$@"
  cat - <<EOF >/etc/init/posm-firstboot.conf
# posm firstboot

description     "POSM First Boot"

start on (local-filesystems and net-device-up IFACE!=lo)

pre-start script
  if [ ! -e "${BOOTSTRAP_HOME}/.posm-firstboot.done" ]; then
    echo "[\`date '+%c'\`] Starting: posm firstboot" >> "${BOOTSTRAP_HOME}/posm-firstboot.log"
    env BOOTSTRAP_HOME="${BOOTSTRAP_HOME}" "${BOOTSTRAP_HOME}/scripts/bootstrap.sh" -F$opt || true
    date '+%c' > "${BOOTSTRAP_HOME}/.posm-firstboot.done"
  fi
end script
EOF
}

bootstrap_init() {
  ks_fetch "scripts/functions.sh" && . "${BOOTSTRAP_HOME}/scripts/functions.sh"

  local i
  for i in etc/settings etc/settings.local; do
    ks_fetch "$i"
    set -a
    test -e "${BOOTSTRAP_HOME}/$i" && . "${BOOTSTRAP_HOME}/$i"
    set +a
  done

  # etc/settings (etc.) doesn't necessarily have authoritative state
  if [[ -f /etc/posm.json ]]; then
    # jq may not be installed yet
    if [[ $(grep -E '"posm_network_bridged":\s?"1"' /etc/posm.json) ]]; then
      # bridged
      export posm_network_bridged=1
    else
      # captive
      export posm_network_bridged=0
    fi
  fi

  kernel_args=$(python3 -c 'import shlex; print("\n".join(shlex.split(None)))' < /proc/cmdline)
  for arg in $kernel_args; do
    if [[ $arg =~ ^posm_ ]]; then
      export ${arg/posm_/}
    fi
  done

  expand etc/posm.json /etc/posm.json

  if [ -n "$debug" ] && [ "$debug" != 0 ]; then
    set -x
  fi
}

bootstrap() {
  local err=0
  local i
  for i in "$@"; do
    if ! ks_fetch "scripts/${i}-deploy.sh"; then
      err=1
      continue
    fi
    chmod +x "${BOOTSTRAP_HOME}/scripts/${i}-deploy.sh"
    echo "==> Deploying: $i"
    if [ -z "$dryrun" ]; then
      if ! . "${BOOTSTRAP_HOME}/scripts/${i}-deploy.sh"; then
        err=1
      fi
    fi
  done
  return $err
}

# first pass
OPTSTRING="Ffhk:nrs:x"
while getopts "$OPTSTRING" opt; do
  case $opt in
    f)
      firstboot=1
      ;;
    h)
      usage
      exit
      ;;
    k)
      export KS="$OPTARG"
      ;;
    n)
      dryrun=1
      ;;
    x)
      debug=1
      set -x
      ;;
  esac
done

exec &> >(tee -a "${BOOTSTRAP_HOME}/bootstrap.log")
echo "[`date '+%c'`] Starting bootstrap: $0 $*"
echo "$0 $*" >>/root/.bash_history
echo -e '\n********** POSM BOOTSTRAP IS RUNNING!!! **********\n' >/etc/motd

bootstrap_init

# second pass (variables)
OPTIND=0
while getopts "$OPTSTRING" opt; do
  case $opt in
    F)
      firstboot=0
      ;;
    s)
      set -a
      eval "$OPTARG"
      set +a
      ;;
    r)
      reboot=1
      ;;
  esac
done

if [ x"$firstboot" = x"1" ]; then
  bootstrap_firstboot "$@"
  err=$?
  reboot=0
else
  shift $(expr $OPTIND - 1)
  bootstrap "$@"
  err=$?
fi

echo "[`date '+%c'`] Bootstrap complete: $err"
rm /etc/motd

case "$reboot" in
  1|[Yy]*|[Tt]*)
    echo "[`date '+%c'`] Rebooting..."
    if [ -z "$dryrun" ]; then
      /sbin/shutdown -r now "BOOTSTRAP RESTART"
      sleep 900
      /sbin/reboot -f
    fi
    ;;
esac

exit $err
