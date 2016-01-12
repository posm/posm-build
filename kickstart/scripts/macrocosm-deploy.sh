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
  echo -e "${macrocosm_pg_pass}\n${macrocosm_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$macrocosm_pg_owner'"
  su - postgres -c "createdb --owner='$macrocosm_pg_owner' 'macrocosm_$posm_env'"
  su - postgres -c "psql --dbname='macrocosm_$posm_env' --command='CREATE EXTENSION btree_gist'"
  su - macrocosm -c "psql --dbname='macrocosm_$posm_env' -f '$dst/db-server/script/macrocosm-db.sql'"

  # start
  expand etc/macrocosm.upstart /etc/init/macrocosm.conf
  start macrocosm
}

deploy macrocosm
