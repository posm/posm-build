#!/bin/bash

deploy_telegraf_ubuntu() {
  mkdir -p "${BOOTSTRAP_HOME}/sources"
  wget -q -N -P "${BOOTSTRAP_HOME}/sources" https://dl.influxdata.com/telegraf/releases/telegraf_1.3.1-1_amd64.deb
  dpkg -i "${BOOTSTRAP_HOME}/sources/telegraf_1.3.1-1_amd64.deb"

  for f in ${BOOTSTRAP_HOME}/etc/telegraf/telegraf.d/*.conf; do
    expand "etc/telegraf/telegraf.d/$(basename $f)" "/etc/telegraf/telegraf.d/$(basename $f)"
  done

  service telegraf restart
}

deploy telegraf
