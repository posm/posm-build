#!/bin/bash

deploy_webodm_ubuntu() {
  useradd -c 'WebODM' -d "/opt/webodm" -m -r -s /bin/bash -U webodm
  mkdir -p /opt/data/webodm/project
  chown -R webodm:webodm /opt/data/webodm

  echo -e "${webodm_pg_pass}\n${webodm_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$webodm_pg_owner'"
  su - postgres -c "createdb --owner='$webodm_pg_owner' '$webodm_pg_dbname'"
  su - postgres -c "psql --dbname='$webodm_pg_dbname' --command='CREATE EXTENSION postgis'"
  su - postgres -c "psql --dbname='$webodm_pg_dbname' --command='ALTER DATABASE $webodm_pg_dbname SET postgis.gdal_enabled_drivers TO 'GTiff';'"
  su - postgres -c "psql --dbname='$webodm_pg_dbname' --command='ALTER DATABASE $webodm_pg_dbname SET postgis.enable_outdb_rasters TO True;'"

  docker pull opendronemap/webodm_webapp@${webodm_webapp_digest}

  expand etc/webodm.py.hbs /etc/webodm.py

  expand etc/systemd/system/webodm-web.service.hbs /etc/systemd/system/webodm-web.service
  expand etc/systemd/system/webodm-worker.service.hbs /etc/systemd/system/webodm-worker.service

  mkdir -p /opt/webodm/app/static/app/js/classes
  mkdir -p /opt/webodm/plugins/osm-quickedit/public

  expand etc/webodm/app/static/app/js/classes/Basemaps.js /opt/webodm/app/static/app/js/classes/Basemaps.js
  expand etc/webodm/plugins/osm-quickedit/public/main.js /opt/webodm/plugins/osm-quickedit/public/main.js

  systemctl enable --now webodm-web
  systemctl enable --now webodm-worker

  # wait for Docker containers to come online
  echo Waiting for WebODM to become available...
  while ! (docker ps | grep -q webodm-web.service); do
    sleep 1
  done

  docker exec webodm-web.service /webodm/wait-for-it.sh -t 0 localhost:8000
  docker exec webodm-web.service python manage.py shell -c "from django.contrib.auth.models import User; User.objects.create_superuser('$webodm_user', '', '$webodm_password')"
  docker exec webodm-web.service python manage.py shell -c "from nodeodm.models import ProcessingNode; ProcessingNode.objects.update_or_create(hostname='nodeodm.service', defaults={'hostname': 'nodeodm.service', 'port': 3000})"

  # add the nginx config for the WebODM virtualhost
  expand etc/nginx-webodm.conf /etc/nginx/sites-available/webodm
  ln -s -f ../sites-available/webodm /etc/nginx/sites-enabled/
  service nginx restart

  apps=$(jq .apps /opt/posm-www/config.json)
  new_apps=$(cat << EOF | jq -s '.[0] + .[1] | unique'
[
  {
    "name": "WebODM",
    "icon": "airplane",
    "url": "//${webodm_fqdn}/"
  }
]
$apps
EOF
)

  config=$(jq . /opt/posm-www/config.json)
  cat << EOF | jq -s '.[0] * .[1]' > /opt/posm-www/config.json
$config
{
  "apps": $new_apps
}
EOF

  mkdir -p /opt/data/backups/webodm
  chown webodm:webodm /opt/data/backups/webodm
}

deploy webodm
