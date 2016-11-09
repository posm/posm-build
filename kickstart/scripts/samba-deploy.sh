#!/bin/bash

deploy_samba_ubuntu() {
  apt-get install --no-install-recommends -y samba

  # writable spot to share files with other POSM users
  mkdir -p /opt/data/public
  chown nobody:nogroup /opt/data/public
  chmod 777 /opt/data/public

  # writable spot to put Field Papers snapshots
  mkdir -p /opt/data/fieldpapers
  chown nobody:nogroup /opt/data/fieldpapers
  chmod 777 /opt/data/fieldpapers

  # read-only spot to copy backups from
  mkdir -p /opt/data/backups
  chmod 644 /opt/data/backups

  expand etc/smb.conf /etc/samba/smb.conf

  service samba restart
}

deploy samba
