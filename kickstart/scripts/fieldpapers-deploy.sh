#!/bin/sh

dst=/opt/fp

mysql_pw="${mysql_pw:-}"

fieldpapers_deploy_ubuntu() {
  # deps
  apt-get install -y \
    build-essential \
    ghostscript \
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

  # gems
  gem install --no-rdoc --no-ri bundler
  gem install --no-rdoc --no-ri foreman

  # FP user & env
  useradd -c 'Field Papers' -d "$dst" -m -r -s /bin/bash -U fp
  cat - <<"EOF" >"$dst/.bashrc"
if [ -e "$HOME/fp-web/.env" ]; then
  set -a
  . "$HOME/fp-web/.env"
  set +a
fi
for d in "$HOME/bin" "$HOME"/*/bin; do
  if [ -d "$d" ]; then
    PATH="$PATH:$d"
  fi
done
EOF

  # install FP
  from_github "https://github.com/fieldpapers/fp-web" "$dst/fp-web"
  chown -R fp:fp "$dst"
  # FIXME: remove next line
  sed -i -e 's/2\.2\.2/2.2.3/' $dst/fp-web/.ruby_version $dst/fp-web/Gemfile

  # configure FP
  cat - <<EOF >"$dst/fp-web/.env"
DATABASE_URL="mysql2://root:${mysql_pw}@localhost/fieldpapers_development"
TEST_DATABASE_URL="mysql2://root:${mysql_pw}@localhost/fieldpapers_test"
AWS_ACCESS_KEY_ID="redacted"
AWS_SECRET_ACCESS_KEY="redacted"
S3_BUCKET_NAME="redacted"
EOF

  # install vendored deps
  su - fp -c "cd \"$dst/fp-web\" && bundle install -j `grep -c rocessor /proc/cpuinfo` --path vendor/bundle"

  # init database
  su - fp -c "cd \"$dst/fp-web\" && rake db:create && rake db:schema:load"

  echo "==> Start FP-WEB with: sudo su - fp -c \"rails server -b 0.0.0.0\""
}

deploy fieldpapers
