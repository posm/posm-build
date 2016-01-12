#!/bin/bash

dst=/opt/macrocosm

deploy_macrocosm_ubuntu() {
  # deps
  apt-get install -y \
    build-essential

  # add user
  useradd -c 'Macrocosm' -d "$dst" -m -r -s /bin/bash -U macrocosm

  # install macrocosm
  from_github "https://github.com/AmericanRedCross/macrocosm" "$dst" "develop"
  chown -R macrocosm:macrocosm "$dst"
  su - macrocosm -c "cd '$dst' && npm install"

  # deploy macrocosm db
  su - postgres -c "createuser --no-superuser --no-createdb --no-createrole '{{macrocosm_pg_owner}}'"
  su - postgres -c "createdb -O '{{macrocosm_pg_owner}}' 'macrocosm_{{posm_env}}'"

  # start
  expand etc/macrocosm.upstart /etc/init/macrocosm.conf
  start macrocosm
}

deploy macrocosm
