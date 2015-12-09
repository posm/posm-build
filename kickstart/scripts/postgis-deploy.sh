#!/bin/bash

deploy_postgis_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:ubuntugis/ppa -y
  apt-get update
  apt-get install postgis -y
}

deploy postgis
