#!/bin/bash

deploy_influxdb_ubuntu() {
  mkdir -p "${BOOTSTRAP_HOME}/sources"
  wget -q -N -P "${BOOTSTRAP_HOME}/sources" https://dl.influxdata.com/influxdb/releases/influxdb_1.6.0_amd64.deb
  dpkg -i "${BOOTSTRAP_HOME}/sources/influxdb_1.6.0_amd64.deb"

  service influxdb start
}

deploy influxdb
