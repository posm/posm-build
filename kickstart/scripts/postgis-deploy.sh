#!/bin/bash

pgsql_ver="${pgsql_ver:-9.3}"
postgis_ver="${postgis_ver:-2.1}"

deploy_postgis_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:ubuntugis/ppa -y
  apt-get update
  apt-get install -y \
    postgis \
    "postgresql-$pgsql_ver-postgis-$postgis_ver" \
    "postgresql-$pgsql_ver-postgis-scripts"
}

deploy postgis
