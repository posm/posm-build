#!/bin/bash

deploy_redis_ubuntu() {
  docker pull redis
  docker create --name redis --network host redis

  expand etc/systemd/system/redis.service.hbs /etc/systemd/system/redis.service
  systemctl enable --now redis
}

deploy redis
