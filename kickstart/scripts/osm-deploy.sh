#!/bin/bash

osmosis_ver="${osmosis_ver:-0.44.1}"

deploy_osm_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:kakrueger/openstreetmap -y
  apt-get update
  apt-get install -y \
    default-jre-headless
  apt-get install -y \
    libmapnik2.2 \
    libmapnik2-dev \
    osmpbf-bin libosmpbf-dev \
    python-gdal \
    geotiff-bin \
    ttf-baekmuk

  ubuntu_backport_install osmctools
  ubuntu_backport_install osm2pgsql
  deploy_osmosis_prebuilt

  #backport_osmosis
}

deploy_osmosis_prebuilt() {
  local dst="/opt/osmosis"

  mkdir -p "${BOOTSTRAP_HOME}/sources"
  wget -N -P "${BOOTSTRAP_HOME}/sources" "http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-${osmosis_ver}.tgz"

  mkdir -p "$dst"
  tar -zxf "${BOOTSTRAP_HOME}/sources/osmosis-${osmosis_ver}.tgz" -C "$dst"
  chown -R root:root "$dst"
  chmod -R o-w "$dst"

  ln -s -f "$dst/bin/osmosis" /usr/bin/
}


backport_osmosis() {
  # extra build deps for osmosis
  apt-get install -y \
    default-jdk ivy junit4 ant-optional maven-repo-helper \
    libbatik-java libcommons-codec-java libcommons-compress-java libcommons-dbcp-java libjpf-java libmysql-java libpostgis-java libpostgresql-jdbc-java libspring-beans-java libspring-context-java libspring-jdbc-java libspring-transaction-java libstax2-api-java libosmpbf-java libplexus-classworlds-java libprotobuf-java libwoodstox-java libxz-java    
  ubuntu_backport_install netty-3.9

  ubuntu_backport_install gradle-debian-helper # this fails

  # finally backport osmosis itself
  ubuntu_backport_install osmosis
}

deploy osm
