#!/bin/sh

deploy_tessera_ubuntu() {
  npm install --unsafe-perm -g mapnik@~3.7.2 @mapbox/mbtiles @mapbox/tilelive \
    @mapbox/tilelive-mapnik tilelive-carto tilelive-tmstyle tilelive-tmsource \
    tilelive-file tilelive-http tilelive-mapbox @mapbox/tilejson \
    @mapbox/tilelive-vector tilelive-blend tessera @posm/posm-imagery-updater

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/systemd/system/tessera.service.hbs /etc/systemd/system/tessera.service
  systemctl enable tessera

  service tessera restart

  crontab ${BOOTSTRAP_HOME}/etc/root.crontab
}

deploy tessera
