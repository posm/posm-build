#!/bin/bash

pgsql_ver="${pgsql_ver:-9.5}"
postgis_ver="${postgis_ver:-2.2}"

deploy_postgis_ubuntu() {
  apt-get install --no-install-recommends -y software-properties-common lsb-release
  wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  add-apt-repository -s "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c -s)-pgdg main"
  apt-get update
  apt-get install --no-install-recommends -y \
    postgis \
    "postgresql-$pgsql_ver-postgis-$postgis_ver" \
    "postgresql-$pgsql_ver-postgis-scripts"

  grep -q "0.0.0.0/0" /etc/postgresql/9.5/main/pg_hba.conf || \
    echo "host\tall\tall\t0.0.0.0/0\tmd5" >> /etc/postgresql/9.5/main/pg_hba.conf

  service postgresql restart
}

deploy postgis
