#!/bin/bash

deploy_osm_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:kakrueger/openstreetmap -y
  apt-get update
  apt-get install -y \
    libmapnik2.2 \
    osmosis \
    osmpbf-bin libosmpbf-dev \
    python-gdal \
    geotiff-bin \
    ttf-baekmuk

  ubuntu_backport_install osmctools
  ubuntu_backport_install osm2pgsql

  #backport_osmosis
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
