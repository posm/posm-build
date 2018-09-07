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

  expand etc/systemd/system/imagery-updater.service /etc/systemd/system/imagery-updater.service
  expand etc/systemd/system/imagery-updater.timer /etc/systemd/system/imagery-updater.timer
  systemctl enable imagery-updater.timer
  systemctl start imagery-updater.timer
  # run the service to kick things off
  systemctl start imagery-updater.service
}

deploy tessera
