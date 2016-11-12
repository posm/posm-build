#!/bin/bash

dst=/opt/admin
deployments_dir=/opt/data/deployments
api_db_dumps_dir=/opt/data/api-db-dumps
aoi_dir=/opt/data/aoi
omk_deployments_dir=/opt/omk/OpenMapKitServer/data/deployments
user="posm-admin"
group="posm-admin"

deploy_admin_ubuntu() {
  # admin user
  useradd -c 'POSM admin' -d "$dst" -m -r -s /bin/bash -U $user
  mkdir -p "$dst"
  mkdir -p "$dst/tmp"
  mkdir -p "$deployments_dir"
  mkdir -p "$api_db_dumps_dir"
  mkdir -p "$aoi_dir"
  chown $user:$group "$dst"
  chown $user:$group "$dst/tmp"
  chown $user:$group "$deployments_dir"
  chown $user:$group "$api_db_dumps_dir"
  chmod -R a+rwx "$dst/tmp"
  chmod -R a+rx "$deployments_dir"
  chmod -R a+rwx "$api_db_dumps_dir"
  chmod -R a+rwx "$aoi_dir"

  # Have OpenMapKit Server refer to this new deployments directory instead of default.
  rm -rf $omk_deployments_dir
  ln -s $deployments_dir $omk_deployments_dir

  deploy_posm_admin
  setup_cron
}

deploy_posm_admin() {
  # Fetch source code.
  from_github "https://github.com/AmericanRedCross/posm-admin" "$dst/posm-admin"

  # admin user should own this
  chown -R $user:$group "$dst/posm-admin"

  # grant read and execute rights for other users
  chmod -R 755 $dst/posm-admin/scripts

  export user
  export dst
  expand etc/sudoers.d/posm-admin /etc/sudoers.d/posm-admin
  chmod 600 /etc/suoders.d/posm-admin

  # The dumps should be readable by anyone.
  chmod -R a+r "$api_db_dumps_dir"

  # install node packages
  su - $user -c "cd $dst/posm-admin && npm install"

  # start
  expand etc/posm-admin.upstart /etc/init/posm-admin.conf
  service posm-admin restart
}

# Occasionally we run cron jobs in the background. For example, we update periodically the render db.
setup_cron() {
  echo "Setting up admin crontab..."

  # # We are having render-db-update.sh run every half hour.
  # su - $user -c 'echo "0,30 * * * * /opt/admin/posm-admin/scripts/render-db-update.sh" > cronfile'
  #
  # #install new cron file
  # su - $user -c 'crontab cronfile'
  # su - $user -c 'rm cronfile'

}

deploy admin
