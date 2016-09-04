#!/bin/bash

ruby_ver="${ruby_ver:-2.2}"

fromsource=no
ruby_prefix="${ruby_prefix:-/opt/rbenv}"

deploy_ruby_ubuntu() {
  if [ x"$fromsource" = x"yes" ]; then
    apt-get install --no-install-recommends -y \
      build-essential \
      libcurl4-openssl-dev \
      libffi-dev \
      libreadline-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      sqlite3 \
      zlib1g-dev
    deploy_ruby_fromsource
  else
    apt-add-repository -y ppa:brightbox/ruby-ng
    apt-get update
    apt-get install --no-install-recommends -y \
      ruby${ruby_ver} ruby${ruby_ver}-dev
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
