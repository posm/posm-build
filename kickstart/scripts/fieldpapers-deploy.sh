#!/bin/bash

dst=/opt/fp

mysql_pw="${mysql_pw:-}"

deploy_fieldpapers_ubuntu() {
  # deps
  apt-get install -qq -y \
    build-essential \
    ghostscript \
    git \
    libcurl4-openssl-dev \
    libffi-dev \
    libmysqlclient-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libyaml-dev \
    python-software-properties \
    ruby2.2-dev \
    sqlite3 \
    zlib1g-dev

  # FP user & env
  useradd -c 'Field Papers' -d "$dst" -m -r -s /bin/bash -U fp
  mkdir -p "$dst"
  chown fp:fp "$dst"
  cat - <<"EOF" >"$dst/.bashrc"
    # this is for interactive shell, not used by upstart!
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
}

deploy_fp_web() {
  # gems
  gem install --no-rdoc --no-ri bundler
  gem install --no-rdoc --no-ri foreman

  # create a directory for static files
  mkdir -p "$dst/data"
  chown fp:fp "$dst/data"

  # install FP WEB
  from_github "https://github.com/fieldpapers/fp-web" "$dst/fp-web"
  chown -R fp:fp "$dst/fp-web"

  local rbver=`ruby -e 'print RUBY_VERSION'`
  sed -i -e "s/2\\.2\\.[0-9]/$rbver/" "$dst/fp-web/.ruby-version" "$dst/fp-web/Gemfile"

  # configure FP
  expand etc/fp-web.env "$dst/fp-web/.env"

  # install vendored deps
  su - fp -c "cd '$dst/fp-web' && bundle install --quiet -j `nproc` --path vendor/bundle"

  # init database
  su - fp -c "cd '$dst/fp-web' && rake db:create && rake db:schema:load"

  # fp assets
  su - fp -c "cd '$dst/fp-web' && rake assets:precompile"

  # fp tile providers
  expand etc/fp-providers.json "$dst/fp-web/config/providers.json"
  chown fp:fp "$dst/fp-web/config/providers.json"

  # start
  expand etc/fp-web.upstart /etc/init/fp-web.conf
  start fp-web
}

deploy_fp_tiler() {
  # install FP Tiler
  from_github "https://github.com/fieldpapers/fp-tiler" "$dst/fp-tiler"
  chown -R fp:fp "$dst/fp-tiler"

  su - fp -c "cd '$dst/fp-tiler' && npm install --quiet"

  # start
  expand etc/fp-tiler.upstart /etc/init/fp-tiler.conf
  start fp-tiler
}

deploy_fp_tasks() {
  # install FP Tasks
  from_github "https://github.com/fieldpapers/fp-tasks" "$dst/fp-tasks"
  chown -R fp:fp "$dst/fp-tasks"

  su - fp -c "cd '$dst/fp-tasks' && npm install --quiet"

  # start
  expand etc/fp-tasks.upstart /etc/init/fp-tasks.conf
  start fp-tasks
}

deploy_fp_legacy() {
  # System dependencies
  apt-get install -qq -y \
    gdal-bin \
    imagemagick \
    php5-cli \
    python-cairo \
    python-dev \
    python-gdal \
    python-imaging \
    python-numpy \
    python-pip \
    python-requests \
    python-virtualenv \
    qrencode \
    zbar-tools

  mkdir -p "$dst/fp-legacy/bin"
  ln -s -f "$dst/fp-legacy" "/opt/paper"
  mkdir -p /root/sources
  wget -q -O /root/sources/fp-legacy.tar.gz "https://github.com/fieldpapers/fp-legacy/archive/modernize.tar.gz"
  wget -q -O /root/sources/vlfeat.tar.gz "https://github.com/migurski/vlfeat/archive/3340e74126434aa8c9a4175f8c88ce3ee5450b73.tar.gz"
  tar -zxf /root/sources/fp-legacy.tar.gz -C "$dst/fp-legacy" --strip=2 --wildcards "*/decoder"
  tar -zxf /root/sources/vlfeat.tar.gz -C "$dst/fp-legacy/vlfeat" --strip=1

  # configure FP
  expand etc/fp-legacy.env "$dst/fp-legacy/.env"

  chown -R fp:fp "$dst/fp-legacy"

  su - fp -c "make -C '$dst/fp-legacy' C_LDFLAGS='-Wl,--rpath,\\\$\$ORIGIN/ -L./bin/a64 -lvl -lm'"
  su - fp -c "cd '$dst/fp-legacy' && virtualenv env --system-site-packages && env PATH='$dst/fp-legacy/env/bin:$PATH' pip install -r requirements.txt"
}

deploy fieldpapers
