dst=/opt/admin
deployments_dir=/opt/data/deployments

deploy_admin_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    pv
    
  # admin user
  useradd -c 'POSM admin' -d "$dst" -m -r -s /bin/bash -U admin
  mkdir -p "$dst"
  mkdir -p "$deployments_dir"
  chown admin:admin "$dst"
  chown admin:admin "$deployments_dir"
  chmod -R a+rx "$deployments_dir"
  cat - <<"EOF" >"$dst/.bashrc"
    # this is for interactive shell, not used by upstart!
    export PATH="$HOME/env/bin:$PATH"
EOF

  deploy_posm_admin
}

deploy_posm_admin() {
  # Fetch source code.
  from_github "https://github.com/AmericanRedCross/posm-admin" "$dst/posm-admin"

  # admin user should own this
  chown -R admin:admin "$dst/posm-admin"

  # Various scripts should be owned by other users
  chown postgres:postgres "$dst/posm-admin/scripts/api-db-drop-create.sh"
  chown osm:osm "$dst/posm-admin/scripts/api-db-init.sh"
  chown osm:osm "$dst/posm-admin/scripts/api-db-populate.sh"

  # These should be specifically allowed in sudoers to be executed by as other users.
  echo "admin ALL=(postgres) NOPASSWD: $dst/posm-admin/scripts/api-db-drop-create.sh" >> /etc/sudoers
  echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/api-db-init.sh" >> /etc/sudoers
  echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/api-db-populate.sh" >> /etc/sudoers
  echo "admin ALL=(osm) NOPASSWD: $dst/posm-admin/scripts/render-db-api2pbf.sh" >> /etc/sudoers
  echo "admin ALL=(gis) NOPASSWD: $dst/posm-admin/scripts/render-db-pbf2render.sh" >> /etc/sudoers

  # install node packages
  su - admin -c "cd $dst/posm-admin && npm install"

  # start
  expand etc/posm-admin.upstart /etc/init/posm-admin.conf
  service posm-admin restart

  true
}

deploy admin
