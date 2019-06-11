#!/bin/sh

deploy_tessera_ubuntu() {
  npm install --unsafe-perm -g \
    mapnik@~3.7.2 \
    @mapbox/mbtiles@~0.10.0 \
    @mapbox/tilelive@~6.0.0 \
    @mapbox/tilelive-mapnik@~1.0.0 \
    tilelive-carto@~0.8.0 \
    tilelive-tmstyle@~0.8.0 \
    tilelive-tmsource@~0.8.2 \
    tilelive-file@~0.0.3 \
    tilelive-http@~0.14.0 \
    tilelive-mapbox@~0.5.0 \
    @mapbox/tilejson@~1.1.0 \
    @mapbox/tilelive-vector@~4.2.0 \
    tilelive-blend@~0.5.1 \
    tessera@~0.13.1 \
    @posm/posm-imagery-updater

  # configure
  mkdir -p /etc/tessera.conf.d

  expand etc/systemd/system/tessera.service.hbs /etc/systemd/system/tessera.service
  systemctl enable --now tessera

  expand etc/systemd/system/imagery-updater.service /etc/systemd/system/imagery-updater.service
  expand etc/systemd/system/imagery-updater.timer /etc/systemd/system/imagery-updater.timer
  systemctl enable --now imagery-updater.timer
  # run the service to kick things off
  systemctl start imagery-updater.service
}

deploy tessera
