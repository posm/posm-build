#!/bin/bash

deploy_nginx_ubuntu() {
  apt-get install nginx -y
  expand etc/nginx-posm.conf /etc/nginx/sites-available/posm
  expand etc/nginx-captive.conf /etc/nginx/sites-available/captive
  rm /etc/nginx/sites-enabled/default
  ln -s -f ../sites-available/posm /etc/nginx/sites-enabled/
  ln -s -f ../sites-available/captive /etc/nginx/sites-enabled/
  service nginx restart

  mkdir -p /opt/posm-www
  chmod 755 /opt/posm-www

  expand htdocs/index.html /opt/posm-www/index.html
}

deploy nginx
