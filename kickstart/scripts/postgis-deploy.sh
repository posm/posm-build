#!/bin/bash

pgsql_ver="${pgsql_ver:-10}"
postgis_ver="${postgis_ver:-2.4}"

deploy_postgis_ubuntu() {
  apt-get install --no-install-recommends -y \
    "postgresql-$pgsql_ver-postgis-$postgis_ver" \
    "postgresql-$pgsql_ver-postgis-scripts" \
    "postgresql-contrib-$pgsql_ver"

  grep -q "0.0.0.0/0" /etc/postgresql/${pgsql_ver}/main/pg_hba.conf || \
    echo "host	all	all	0.0.0.0/0	md5" >> /etc/postgresql/${pgsql_ver}/main/pg_hba.conf

  grep -qe "^listen_addresses" /etc/postgresql/10/main/postgresql.conf || echo "listen_addresses = '*'" >> /etc/postgresql/10/main/postgresql.conf

  cp ${BOOTSTRAP_HOME}/etc/postgresql/postgresql.conf.local /etc/postgresql/${pgsql_ver}/main/conf.d/local.conf.hbs

  mkdir -p /etc/systemd/system/postgresql@.service.d
  expand etc/systemd/system/postgresql@.service.d/override.conf /etc/systemd/system/postgresql@.service.d/override.conf

  service postgresql restart
}

deploy postgis
