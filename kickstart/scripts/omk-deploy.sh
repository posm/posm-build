#!/bin/bash

dst=/opt/omk

deploy_omk_ubuntu() {
  # OMK user
  useradd -c 'OpenMapKit Server' -d /nonexistent -m -r -s /bin/false -U omk

  deploy_omk_server
}

deploy_omk_server() {
  cat <<EOF > /etc/omk-server.js
module.exports = {
  name: 'OpenMapKit Server',
  description: 'OpenMapKit Server',
  port: ${omk_server_port},
  dataDir: __dirname + '/data',
  pagesDir: __dirname + '/pages',
  hostUrl: '${posm_base_url}',
  osmApi: {
      server: '${osm_base_url}',
      user: 'POSM',
      pass: ''
  }
};
EOF

  # create data directories if necessary
  mkdir -p /opt/data/{forms,submissions}
  chown -R omk:omk /opt/data/{forms,submissions}

  docker create \
    -p ${omk_server_port}:${omk_server_port} \
    -e PORT=${omk_server_port} \
    -e NODE_ENV=${posm_env} \
    --name omk-server \
    --tmpfs /tmp \
    -u "$(id -u omk):$(id -g omk)" \
    --dns ${posm_wlan_ip} \
    -v /etc/omk-server.js:/app/settings.js \
    -v /opt/data/forms:/app/data/forms \
    -v /opt/data/submissions:/app/data/submissions \
    -v /opt/data/deployments:/app/data/deployments \
    quay.io/americanredcross/openmapkitserver

  # create backup directory
  mkdir -p /opt/data/backups/omk
  chown omk:omk /opt/data/backups/omk
  chmod 755 /opt/data/backups/omk

  # start
  expand etc/omk-server.upstart /etc/init/omk-server.conf
  service omk-server restart

  true
}

deploy omk
