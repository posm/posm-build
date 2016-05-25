#!/bin/bash

deploy_samba_ubuntu() {
  apt-get install --no-install-recommends -y samba

  mkdir -p /opt/data/public
  chown nobody:nogroup /opt/data/public
  chmod 777 /opt/data/public

  mkdir -p /opt/data/fieldpapers
  chown nobody:nogroup /opt/data/fieldpapers
  chmod 777 /opt/data/fieldpapers

  mkdir -p /opt/data/backups
  chown nobody:nogroup /opt/data/backups
  chmod 777 /opt/data/backups

  expand etc/smb.conf /etc/samba/smb.conf

  service samba restart
}

deploy samba
