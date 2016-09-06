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

  # writable spot to put input images for ODM
  mkdir -p /opt/data/odm-input
  chown nobody:nogroup /opt/data/odm-input
  chmod 777 /opt/data/odm-input

  # writable spot to put GeoTIFFs for tiling (and where ODM outputs are copied)
  mkdir -p /opt/data/aerial-imagery
  chown nobody:nogroup /opt/data/aerial-imagery
  chmod 777 /opt/data/aerial-imagery

  # read-only spot to copy MBTiles archives from
  mkdir -p /opt/data/mbtiles
  chown nobody:nogroup /opt/data/mbtiles
  chmod 644 /opt/data/mbtiles

  # read-only spot to copy backups from
  mkdir -p /opt/data/backups
  chmod 644 /opt/data/backups

  expand etc/smb.conf /etc/samba/smb.conf

  service samba restart
}

deploy samba
