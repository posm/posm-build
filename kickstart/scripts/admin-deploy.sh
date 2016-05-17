#!/bin/bash

dst=/opt/admin
deployments_dir=/opt/data/deployments
api_db_dumps_dir=/opt/data/api-db-dumps
fp_db_dumps_dir=/opt/data/fp-db-dumps
omk_data_dumps_dir=/opt/data/omk-data-dumps
aoi_dir=/opt/data/aoi
omk_deployments_dir=/opt/omk/OpenMapKitServer/data/deployments

deploy_admin_ubuntu() {
  # deps
  apt-get update
  apt-get install --no-install-recommends -y \
    pv

  # admin user
  useradd -c 'POSM admin' -d "$dst" -m -r -s /bin/bash -U admin
  mkdir -p "$dst"
  mkdir -p "$dst/tmp"
  mkdir -p "$deployments_dir"
  mkdir -p "$api_db_dumps_dir"
  mkdir -p "$fp_db_dumps_dir"
  mkdir -p "$omk_data_dumps_dir"
  mkdir -p "$aoi_dir"
  chown admin:admin "$dst"
  chown admin:admin "$dst/tmp"
  chown admin:admin "$deployments_dir"
  chown admin:admin "$api_db_dumps_dir"
  chown admin:admin "$fp_db_dumps_dir"
  chown admin:admin "$omk_data_dumps_dir"
  chmod -R a+rwx "$dst/tmp"
  chmod -R a+rx "$deployments_dir"
  chmod -R a+rwx "$api_db_dumps_dir"
  chmod -R a+rwx "$fp_db_dumps_dir"
  chmod -R a+rwx "$omk_data_dumps_dir"
  chmod -R a+rwx "$aoi_dir"

  # Have OpenMapKit Server refer to this new deployments directory instead of default.
  rm -rf $omk_deployments_dir
  ln -s $deployments_dir $omk_deployments_dir

  deploy_posm_admin
  setup_cron
}

deploy_posm_admin() {
  # Fetch source code.
  from_github "https://github.com/AmericanRedCross/posm-admin/tarball/master_backup" "$dst/posm-admin"

  # admin user should own this
  chown -R admin:admin "$dst/posm-admin"
  chmod a+rx $dst/posm-admin/scripts/*

  # Various scripts should be owned by other users
  chown postgres:postgres "$dst/posm-admin/scripts/postgres_api-db-backup.sh"
  chown postgres:postgres "$dst/posm-admin/scripts/postgres_api-db-drop-create.sh"
  chown osm:osm "$dst/posm-admin/scripts/osm_api-db-init.sh"
  chown osm:osm "$dst/posm-admin/scripts/osm_api-db-populate.sh"
  chown osm:osm "$dst/posm-admin/scripts/osm_render-db-api2pbf.sh"
  chown gis:gis "$dst/posm-admin/scripts/gis_render-db-pbf2render.sh"

  # These should be specifically allowed in sudoers to be executed by as other users.
  grep -q postgres_api-db-backup /etc/sudoers || echo "admin ALL=(postgres) NOPASSWD: $dst/posm-admin/scripts/postgres_api-db-backup.sh" >> /etc/sudoers
  grep -q postgres_api-db-drop-create /etc/sudoers || echo "admin ALL=(postgres) NOPASSWD: $dst/posm-admin/scripts/postgres_api-db-drop-create.sh" >> /etc/sudoers
  grep -q osm_api-db-init.sh /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/osm_api-db-init.sh" >> /etc/sudoers
  grep -q osm_api-db-populate.sh /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/osm_api-db-populate.sh" >> /etc/sudoers
  grep -q osm_render-db-api2pbf /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/osm_render-db-api2pbf.sh" >> /etc/sudoers
  grep -q gis_render-db-pbf2render /etc/sudoers || echo "admin ALL=(gis) NOPASSWD: $dst/posm-admin/scripts/gis_render-db-pbf2render.sh" >> /etc/sudoers
  grep -q tessera /etc/sudoers || echo "admin ALL=(root) NOPASSWD: /usr/sbin/service tessera restart" >> /etc/sudoers
  grep -q fp-web /etc/sudoers || echo "admin ALL=(root) NOPASSWD: /usr/sbin/service fp-web restart" >> /etc/sudoers
  grep -q root_change-osm-id-key.sh /etc/sudoers || echo "osm ALL=(root) NOPASSWD: $dst/posm-admin/scripts/root_change-osm-id-key.sh" >> /etc/sudoers
  grep -q osm_omk-osm.sh /etc/sudoers || echo "admin ALL=(osm) NOPASSWD: /opt/admin/posm-admin/scripts/osm_omk-osm.sh" >> /etc/sudoers
  grep -q gis_omk-posm-mbtiles.sh /etc/sudoers || echo "admin ALL=(gis) NOPASSWD: /opt/admin/posm-admin/scripts/gis_omk-posm-mbtiles.sh" >> /etc/sudoers
  grep -q gis_omk-aoi-mbtiles.sh /etc/sudoers || echo "admin ALL=(gis) NOPASSWD: /opt/admin/posm-admin/scripts/gis_omk-aoi-mbtiles.sh" >> /etc/sudoers

  # The dumps should be readable by anyone.
  chmod -R a+r "$api_db_dumps_dir"
  chmod -R a+r "$fp_db_dumps_dir"
  chmod -R a+r "$omk_data_dumps_dir"

  # install node packages
  su - admin -c "cd $dst/posm-admin && npm install"

  # start
  expand etc/posm-admin.upstart /etc/init/posm-admin.conf
  service posm-admin restart
}

# Occasionally we run cron jobs in the background. For example, we update periodically the render db.
setup_cron() {
  echo "Setting up admin crontab..."

  # We are having render-db-update.sh run every half hour.
  su - admin -c 'echo "0,30 * * * * /opt/admin/posm-admin/scripts/render-db-update.sh" > cronfile'

  #install new cron file
  su - admin -c 'crontab cronfile'
  su - admin -c 'rm cronfile'

}

deploy admin
