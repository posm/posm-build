dst=/opt/admin

deploy_admin_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    pv
    
  # admin user
  useradd -c 'POSM admin' -d "$dst" -m -r -s /bin/bash -U admin
  mkdir -p "$dst"
  chown admin:admin "$dst"
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

  # install node packages
  su - admin -c "cd $dst/posm-admin && npm install"

  # start
  expand etc/posm-admin.upstart /etc/init/posm-admin.conf
  service posm-admin restart

  true
}

deploy admin
  
