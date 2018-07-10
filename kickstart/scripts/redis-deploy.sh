#!/bin/bash

deploy_redis_ubuntu() {
  docker pull redis
  docker create --name redis redis

  expand etc/systemd/system/redis.service.hbs /etc/systemd/system/redis.service
  systemctl enable redis

  service redis start
}

deploy redis
