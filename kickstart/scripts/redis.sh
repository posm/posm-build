#!/bin/bash

deploy_redis_ubuntu() {
  docker pull redis
  docker create --name redis redis

  expand etc/redis.upstart /etc/init/redis.conf
}

deploy redis
