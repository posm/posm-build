#!/bin/sh

chroot /target mount -t proc proc /proc
chroot /target mount -t sysfs sysfs /sys
chroot /target mount -t securityfs securityfs /sys/kernel/security
mount --bind /dev /target/dev
mount --bind /run /target/run

awk '{print $1}' /cdrom/casper/filesystem-remove.manifest | xargs chroot /target apt-get purge -y
chroot /target apt-get autoremove
# TODO split wifi into package installation and configuration
chroot /target /root/posm-build/kickstart/scripts/bootstrap.sh wifi captive
chroot /target ln -s /root/posm-build/kickstart/scripts /root/scripts
chroot /target ln -s /root/posm-build/kickstart/etc /root/etc
