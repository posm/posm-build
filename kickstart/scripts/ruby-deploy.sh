#!/bin/bash

ruby_ver="${ruby_ver:-2.5}"

deploy_ruby_ubuntu() {
  apt-add-repository -y ppa:brightbox/ruby-ng
  apt-get update
  apt-get install --no-install-recommends -y \
    ruby${ruby_ver} ruby${ruby_ver}-dev

  deploy_ruby_generic
}

deploy_ruby_generic() {
  gem install --no-rdoc --no-ri bundler
}

deploy ruby
