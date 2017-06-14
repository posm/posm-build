#!/bin/sh

deploy_tessera_ubuntu() {
  npm install -g mapnik@~3.6.1 @mapbox/mbtiles @mapbox/tilelive \
    @mapbox/tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource \
    tilelive-file tilelive-http tilelive-mapbox @mapbox/tilejson \
    @mapbox/tilelive-vector tilelive-blend tessera @posm/posm-imagery-updater

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/tessera.upstart /etc/init/tessera.conf

  service tessera restart

  crontab -u osm ${BOOTSTRAP_HOME}/etc/root.crontab
}

deploy tessera
