#!/bin/bash

deploy_gis_ubuntu() {
  apt-get install -y \
    gdal-bin proj-bin spatialite-bin
}

deploy gis
