#!/bin/sh

ruby_ver="${ruby_ver:-2.2}"

fromsource=no
ruby_prefix="${ruby_prefix:-/opt/rbenv}"

deploy_ruby_ubuntu() {
  if [ x"$fromsource" = x"yes" ]; then
    apt-get install -y \
      build-essential \
      curl \
      git \
      libcurl4-openssl-dev \
      libffi-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      python-software-properties \
      sqlite3 \
      zlib1g-dev
    deploy_ruby_fromsource
  else
    apt-get install software-properties-common -y
    apt-add-repository ppa:brightbox/ruby-ng -y
    apt-get update
    apt-get install ruby${ruby_ver} -y
  fi
  deploy_ruby_generic
}

deploy_ruby_fromsource() {
  from_github https://github.com/rbenv/rbenv "$ruby_prefix"

  from_github https://github.com/sstephenson/ruby-build "$ruby_prefix/plugins/ruby-build"

  export PATH="$PATH:$ruby_prefix/bin:$ruby_prefix/plugins/ruby-build/bin"
  export RBENV_ROOT="$ruby_prefix"
  eval "$(rbenv init -)"

  rbenv install -v $ruby_ver
  rbenv global $ruby_ver
}

deploy_ruby_generic() {
  gem install --no-rdoc --no-ri bundler
}

deploy ruby
