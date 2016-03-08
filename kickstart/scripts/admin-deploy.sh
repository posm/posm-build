#!/bin/bash

dst=/opt/admin
deployments_dir=/opt/data/deployments
api_db_dumps_dir=/opt/data/api-db-dumps

deploy_admin_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    pv

  # admin user
  useradd -c 'POSM admin' -d "$dst" -m -r -s /bin/bash -U admin
  mkdir -p "$dst"
  mkdir -p "$dst/tmp"
  mkdir -p "$deployments_dir"
  mkdir -p "$api_db_dumps_dir"
  chown admin:admin "$dst"
  chown admin:admin "$dst/tmp"
  chown admin:admin "$deployments_dir"
  chown admin:admin "$api_db_dumps_dir"
  chmod -R a+rwx "$dst/tmp"
  chmod -R a+rx "$deployments_dir"
  chmod -R a+rwx "$api_db_dumps_dir"

  deploy_posm_admin
}

deploy_posm_admin() {
  # Fetch source code.
  from_github "https://github.com/AmericanRedCross/posm-admin" "$dst/posm-admin"

  # admin user should own this
  chown -R admin:admin "$dst/posm-admin"
  chmod a+rx $dst/posm-admin/scripts/*

  # Various scripts should be owned by other users
  chown postgres:postgres "$dst/posm-admin/scripts/api-db-drop-create.sh"
  chown osm:osm "$dst/posm-admin/scripts/api-db-init.sh"
  chown osm:osm "$dst/posm-admin/scripts/api-db-populate.sh"
  chown osm:osm "$dst/posm-admin/scripts/render-db-api2pbf.sh"
  chown gis:gis "$dst/posm-admin/scripts/render-db-pbf2render.sh"

  # These should be specifically allowed in sudoers to be executed by as other users.
  grep -q api-db-drop-create /etc/sudoers || echo "admin ALL=(postgres) NOPASSWD: $dst/posm-admin/scripts/api-db-drop-create.sh" >> /etc/sudoers
  grep -q osm_api-db-init.sh /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/osm_api-db-init.sh" >> /etc/sudoers
  grep -q api-db-populate /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/api-db-populate.sh" >> /etc/sudoers
  grep -q render-db-api2pbf /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/render-db-api2pbf.sh" >> /etc/sudoers
  grep -q render-db-pbf2render /etc/sudoers || echo "admin ALL=(gis) NOPASSWD: $dst/posm-admin/scripts/render-db-pbf2render.sh" >> /etc/sudoers
  grep -q tessera /etc/sudoers || echo "admin ALL=(root) NOPASSWD: /usr/sbin/service tessera restart" >> /etc/sudoers
  grep -q fp-web /etc/sudoers || echo "admin ALL=(root) NOPASSWD: /usr/sbin/service fp-web restart" >> /etc/sudoers
  grep -q root_change-osm-id-key.sh || echo "osm ALL=(root) NOPASSWD: $dst/posm-admin/scripts/root_change-osm-id-key.sh" >> /etc/sudoers

  # The dumps should be readable by anyone.
  chmod -R a+r "$api_db_dumps_dir"


  # install node packages
  su - admin -c "cd $dst/posm-admin && npm install"

  # start
  expand etc/posm-admin.upstart /etc/init/posm-admin.conf
  service posm-admin restart
}

deploy admin
