#!/bin/bash

deploy_celery_ubuntu() {
  # explicitly with recommended packages so we get wheels and build tools
  apt install -y \
    python-pip
    rabbitmq-server

  pip install 'celery>3'
}

deploy celery
