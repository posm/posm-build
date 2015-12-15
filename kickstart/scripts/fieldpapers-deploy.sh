#!/bin/bash

dst=/opt/fp

mysql_pw="${mysql_pw:-}"

deploy_fieldpapers_ubuntu() {
  # deps
  apt-get install -y \
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
}

deploy_fp_web() {
  # gems
  gem install --no-rdoc --no-ri bundler
  gem install --no-rdoc --no-ri foreman

  # install FP WEB
  from_github "https://github.com/fieldpapers/fp-web" "$dst/fp-web"
  chown -R fp:fp "$dst/fp-web"

  # configure FP
  expand etc/fp-web.env "$dst/fp-web/.env"

  # install vendored deps
  su - fp -c "cd \"$dst/fp-web\" && bundle install -j `grep -c rocessor /proc/cpuinfo` --path vendor/bundle"

  # init database
  su - fp -c "cd \"$dst/fp-web\" && rake db:create && rake db:schema:load"

  # start
  expand etc/fp-web.upstart /etc/init/fp-web.conf
  start fp-web
}

deploy_fp_tiler() {
  # install FP Tiler
  from_github "https://github.com/fieldpapers/fp-tiler" "$dst/fp-tiler"
  chown -R fp:fp "$dst/fp-tiler"

  su - fp -c "cd \"$dst/fp-tiler\" && npm install"

  # start
  expand etc/fp-tiler.upstart /etc/init/fp-tiler.conf
  start fp-tiler
}

deploy fieldpapers
