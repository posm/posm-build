#!/bin/bash

deploy_celery_ubuntu() {
  # explicitly with recommended packages so we get wheels and build tools
  apt install -y \
    python-pip
    rabbitmq-server

  pip install 'celery>3'
  pip install -e 'git+https://github.com/celery/billiard.git#egg=billiard'
  pip install -e 'git+https://github.com/celery/kombu.git#egg=kombu'
}

deploy celery
