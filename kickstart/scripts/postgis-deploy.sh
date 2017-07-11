#!/bin/bash

pgsql_ver="${pgsql_ver:-9.6}"
postgis_ver="${postgis_ver:-2.3}"

deploy_postgis_ubuntu() {
  wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c -s)-pgdg main" > /etc/apt/sources.list.d/postgresql.list
  apt-get update
  apt-get install --no-install-recommends -y \
    postgis \
    "postgresql-$pgsql_ver-postgis-$postgis_ver" \
    "postgresql-$pgsql_ver-postgis-scripts" \
    "postgresql-contrib-$pgsql_ver"

  grep -q "0.0.0.0/0" /etc/postgresql/${pgsql_ver}/main/pg_hba.conf || \
    echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/${pgsql_ver}/main/pg_hba.conf

  grep -q "postgresql.conf.local" /etc/postgresql/${pgsql_ver}/main/postgresql.conf || \
    echo "include '/etc/postgresql/${pgsql_ver}/main/postgresql.conf.local'" >> /etc/postgresql/${pgsql_ver}/main/postgresql.conf

  cp ${BOOTSTRAP_HOME}/etc/postgresql/postgresql.conf.local /etc/postgresql/${pgsql_ver}/main/postgresql.conf.local.hbs

  expand etc/init.d/postgresql /etc/init.d/postgresql

  service postgresql restart
}

deploy postgis
