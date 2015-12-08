#!/bin/sh

deploy_osm_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:kakrueger/openstreetmap -y
  apt-get update
  apt-get install mapnik osm2pgsql osmosis osmpbf python-gdal geotiff-bin ttf-baekmuk -y
  #apt-get install libapache2-mod-tile apache2-utils
}

deploy osm
