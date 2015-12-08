#!/bin/sh

deploy_gis_ubuntu() {
  apt-get install python-software-properties -y
  add-apt-repository ppa:ubuntugis/ppa -y
  apt-get update
  apt-get install -y \
    freexl \
    gdal \
    geos \
    proj \
    spatialite \
    spatialite-tools
}

deploy_gis_rhel() {
  r=`lsb_release -sr | cut -d. -f 1`
  rpm -Uvh "http://elgis.argeo.org/repos/$r/elgis-release-$r-${r}_0.noarch.rpm"
  yum install gdal gdal-python geos geos-python libgeotiff libspatialite proj
}

deploy gis
