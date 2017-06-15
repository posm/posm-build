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
  chmod 755 /opt/data/backups

  expand etc/smb.conf /etc/samba/smb.conf
  expand etc/init/smbd.override /etc/init/smbd.override

  curl -sfL https://github.com/AmericanRedCross/OpenMapKitAndroid/releases/download/v1.2/OpenMapKit_v1.2.apk -o /opt/data/public/OpenMapKit_v1.2.apk
  curl -sfL https://opendatakit.org/download/4489/ -o /opt/data/public/ODKCollect_v1.4.1.apk

  service samba restart
}

deploy samba
