#!/bin/sh

deploy_tessera_ubuntu() {
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  apt-get update
  apt-get install -y libstdc++6

  npm install -g mapnik@~3.7.2 @mapbox/mbtiles @mapbox/tilelive \
    @mapbox/tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource \
    tilelive-file tilelive-http tilelive-mapbox @mapbox/tilejson \
    @mapbox/tilelive-vector tilelive-blend tessera @posm/posm-imagery-updater

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart

  crontab ${BOOTSTRAP_HOME}/etc/root.crontab
}

deploy tessera
