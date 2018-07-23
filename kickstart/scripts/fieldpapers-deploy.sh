#!/bin/bash

dst=/opt/fp

ruby_prefix="${ruby_prefix:-/opt/rbenv}"

deploy_fieldpapers_ubuntu() {
  # deps
  apt-get install --no-install-recommends -y \
    build-essential \
    ghostscript \
    git \
    libcurl4-openssl-dev \
    libffi-dev \
    libpq-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    sqlite3 \
    zlib1g-dev \
    inotify-tools

  # FP user & env
  useradd -c 'Field Papers' -d "$dst" -m -r -s /bin/bash -U fp
  mkdir -p "$dst"
  chown fp:fp "$dst"
  cat - << "EOF" > "$dst/.bashrc"
# this is for interactive shells
for d in "$HOME" "$HOME"/fp-*; do
  if [ -e "$d/bin" ]; then
    PATH="$PATH:$d/bin"
  fi
  if [ -e "$d/.env" ]; then
    set -a
    . "$d/.env"
    set +a
  fi
done
EOF

  deploy_fieldpapers_common
}

deploy_fieldpapers_common() {
  deploy_fp_web
  deploy_fp_tiler
  deploy_fp_tasks
  deploy_fp_legacy

  mkdir -p "$dst/bin"
  expand etc/fp-watch.sh "$dst/bin/fp-watch.sh"
  chmod +x "$dst/bin/fp-watch.sh"
  chown -R fp:fp "$dst/bin"

  expand etc/systemd/system/fp-watch.service.hbs /etc/systemd/system/fp-watch.service
  systemctl enable fp-watch

  service fp-watch restart
}

deploy_fp_web() {
  export PATH="$PATH:$ruby_prefix/bin:$ruby_prefix/plugins/ruby-build/bin"
  export RBENV_ROOT="$ruby_prefix"
  eval "$(rbenv init -)"

  # gems
  gem install --no-rdoc --no-ri bundler

  # create a directory for static files
  mkdir -p "$dst/data"
  chown fp:fp "$dst/data"

  # create backup directory
  mkdir -p /opt/data/backups/fieldpapers
  chown fp:fp /opt/data/backups/fieldpapers
  chmod 755 /opt/data/backups/fieldpapers

  # install FP WEB
  from_github "https://github.com/posm/fp-web" "$dst/fp-web"
  chown -R fp:fp "$dst/fp-web"
  chmod -R a+rwx "$dst/fp-web/config"

  local rbver=`ruby -e 'print RUBY_VERSION'`
  sed -i -e "s/2\\.2\\.[0-9]/$rbver/" "$dst/fp-web/.ruby-version" "$dst/fp-web/Gemfile"

  # configure FP
  export ruby_prefix
  expand etc/fp-web.env "$dst/fp-web/.env"
  chown fp:fp "$dst/fp-web/.env"
  expand etc/fieldpapers/database.yml "$dst/fp-web/config/database.yml"

  # install vendored deps
  su - fp -c "cd '$dst/fp-web' && bundle install -j `nproc` --path vendor/bundle --with production"

  # init database
  echo -e "${fp_pg_pass}\n${fp_pg_pass}" | su - postgres -c "createuser --no-superuser --no-createdb --no-createrole --pwprompt '$fp_pg_owner'"
  su - postgres -c "createdb --owner='$fp_pg_owner' '$fp_pg_dbname'"
  su - fp -c "cd '$dst/fp-web' && bundle exec rake db:schema:load"

  # fp assets
  su - fp -c "cd '$dst/fp-web' && bundle exec rake assets:precompile"

  # fp tile providers
  expand etc/fp-providers.json "$dst/fp-web/config/providers.json"
  chown fp:fp "$dst/fp-web/config/providers.json"

  # start
  expand etc/systemd/system/fp-web.service.hbs /etc/systemd/system/fp-web.service
  systemctl enable fp-web
  service fp-web restart

  true
}

deploy_fp_tiler() {
  # install FP Tiler
  from_github "https://github.com/posm/fp-tiler" "$dst/fp-tiler"
  chown -R fp:fp "$dst/fp-tiler"

  su - fp -c "cd '$dst/fp-tiler' && npm install --quiet"

  # start
  expand etc/systemd/system/fp-tiler.service.hbs /etc/systemd/system/fp-tiler.service
  systemctl enable fp-tiler
  service fp-tiler restart

  true
}

deploy_fp_tasks() {
  # install FP Tasks
  from_github "https://github.com/posm/fp-tasks" "$dst/fp-tasks"
  chown -R fp:fp "$dst/fp-tasks"

  su - fp -c "cd '$dst/fp-tasks' && npm install --quiet"

  # start
  expand etc/systemd/system/fp-tasks.service.hbs /etc/systemd/system/fp-tasks.service
  systemctl enable fp-tasks
  service fp-tasks restart

  true
}

deploy_fp_legacy() {
  # System dependencies
  apt-get install --no-install-recommends -y \
    gdal-bin \
    imagemagick \
    php-cli \
    php-mbstring \
    python-cairo \
    python-dev \
    python-gdal \
    python-pil \
    python-numpy \
    python-pip \
    python-requests \
    virtualenv \
    qrencode \
    zbar-tools

  mkdir -p "$dst/fp-legacy/bin"
  ln -s -f "$dst/fp-legacy" "/opt/paper"
  mkdir -p /root/sources
  wget -q -O /root/sources/fp-legacy.tar.gz "https://github.com/posm/fp-legacy/archive/modernize.tar.gz"
  wget -q -O /root/sources/vlfeat.tar.gz "https://github.com/migurski/vlfeat/archive/3340e74126434aa8c9a4175f8c88ce3ee5450b73.tar.gz"
  tar -zxf /root/sources/fp-legacy.tar.gz -C "$dst/fp-legacy" --strip=2 --wildcards "*/decoder"
  tar -zxf /root/sources/vlfeat.tar.gz -C "$dst/fp-legacy/vlfeat" --strip=1


  chown -R fp:fp "$dst/fp-legacy"
  rm -f "$dst/fp-legacy/.env"

  su - fp -c "make -C '$dst/fp-legacy' C_LDFLAGS='-Wl,--rpath,\\\$\$ORIGIN/ -L./bin/a64 -lvl -lm'"
  su - fp -c "cd '$dst/fp-legacy' && virtualenv env --system-site-packages && VIRTUAL_ENV='$dst/fp-legacy/env' PATH='$dst/fp-legacy/env/bin:$PATH' pip install -r requirements.txt"

  # configure FP
  expand etc/fp-legacy.env "$dst/fp-legacy/.env"
}

deploy fieldpapers
