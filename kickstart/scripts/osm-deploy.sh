#!/bin/bash

deploy_osm_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:kakrueger/openstreetmap -y
  apt-get update
  apt-get install -y \
    osm2pgsql \
    osmosis \
    osmpbf-bin libosmpbf-dev \
    python-gdal \
    geotiff-bin \
    ttf-baekmuk

  ubuntu_backport_install osmctools
}

deploy osm
