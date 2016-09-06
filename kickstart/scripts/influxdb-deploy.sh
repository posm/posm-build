#!/bin/bash

deploy_influxdb_ubuntu() {
  mkdir -p "${BOOTSTRAP_HOME}/sources"
  wget -q -N -P "${BOOTSTRAP_HOME}/sources" https://dl.influxdata.com/influxdb/releases/influxdb_0.13.0_amd64.deb
  dpkg -i "${BOOTSTRAP_HOME}/sources/influxdb_0.13.0_amd64.deb"

  service influxdb start
}

deploy influxdb
