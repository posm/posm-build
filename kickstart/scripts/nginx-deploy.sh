#!/bin/bash

deploy_nginx_ubuntu() {
  apt-get install nginx -y
  expand etc/nginx-posm.conf /etc/nginx/sites-available/posm
  rm /etc/nginx/sites-enabled/default
  ln -s -f ../sites-available/posm /etc/nginx/sites-enabled/
  service nginx restart
}

deploy nginx
