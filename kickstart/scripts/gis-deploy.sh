#!/bin/bash

deploy_gis_ubuntu() {
  add-apt-repository -s -y ppa:ubuntugis/ppa
  apt-get update
  apt-get install --no-install-recommends -y \
    libfreexl1 libfreexl-dev \
    gdal-bin libgdal1h libgdal-dev python-gdal \
    libgeos-3.4.2 libgeos-dev \
    proj-bin libproj0 libproj-dev \
    spatialite-bin libspatialite5 libspatialite-dev
}

deploy_gis_rhel() {
  r=`lsb_release -sr | cut -d. -f 1`
  rpm -Uvh "http://elgis.argeo.org/repos/$r/elgis-release-$r-${r}_0.noarch.rpm"
  yum install gdal gdal-python geos geos-python libgeotiff libspatialite proj
}

deploy gis
