#!/bin/sh

deploy_postgis_ubuntu() {
  apt-get install python-software-properties -y
  add-apt-repository ppa:ubuntugis/ppa -y
  apt-get update
  apt-get install postgis -y
}

deploy postgis
