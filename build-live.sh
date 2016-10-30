#!/usr/bin/env bash

set -uio pipefail
set -x

WORK=$(mktemp -d)
CD=~/cd
FORMAT=squashfs
FS_DIR=casper
ARCH=amd64
DIST=trusty
DEBIAN_FRONTEND=noninteractive
DEBCONF_NONINTERACTIVE_SEEN=true
CONTAINER=$(tr -dc 'a-z' < /dev/urandom | head -c12)
GIT_REPO=${GIT_REPO:-https://github.com/AmericanRedCross/posm-build}
GIT_BRANCH=${GIT_BRANCH:-master}

set -x

# TODO start with an ubuntu-14.04-desktop ISO extracted into ${CD}
mkdir -p ${CD}/{${FS_DIR},boot/grub,preseed}

sudo apt update
sudo apt install -y grub2 xorriso squashfs-tools debootstrap

cd $WORK
lxc launch ubuntu:${DIST}/${ARCH} $CONTAINER -p default -p docker \
  -c environment.DEBCONF_NONINTERACTIVE_SEEN=true \
  -c environment.DEBIAN_FRONTEND=noninteractive \
  -c security.privileged=true

# wait for the system to start
sleep 5

lxc exec $CONTAINER -- apt update
lxc exec $CONTAINER -- apt upgrade -y
lxc exec $CONTAINER -- apt install -y ubuntu-standard
lxc exec $CONTAINER -- apt purge -y cloud-init

# install POSM

lxc exec $CONTAINER -- apt install -y --no-install-recommends git
lxc exec $CONTAINER -- git clone $GIT_REPO -b $GIT_BRANCH
set +e
# TODO split wifi into package installation and configuration
lxc exec $CONTAINER -- /root/posm-build/kickstart/scripts/bootstrap.sh base nodejs ruby gis mysql postgis nginx osm fieldpapers omk tl carto tessera admin samba blink1 docker redis opendronemap imagery
set -e

lxc exec $CONTAINER -- apt install --no-install-recommends -y linux-image-generic-lts-xenial wireless-tools
lxc exec $CONTAINER -- apt install --no-install-recommends -y \
  dnsmasq \
  dnsmasq-utils \
  hostapd \
  iw \
  rfkill \
  rng-tools

# grab the list of packages
lxc exec $CONTAINER -- dpkg-query -W --showformat='${Package} ${Version}\n' | sort > ${CD}/${FS_DIR}/filesystem-desktop.manifest

lxc exec $CONTAINER -- apt install -y --no-install-recommends casper

echo "Diverting running-in-container..."
lxc exec $CONTAINER -- dpkg-divert --local --rename --add /bin/running-in-container
echo "Stubbing /bin/running-in-container..."
echo | lxc file push --uid=0 --gid=0 --mode=755 - ${CONTAINER}/bin/running-in-container <<EOF
#!/bin/sh
[ -f /run/container_type ] && cat /run/container_type
exit 0
EOF

echo "Creating policy-rc.d..."
echo | lxc file push --uid=0 --gid=0 --mode 755 - ${CONTAINER}/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF

# Move initctl out of the way, install dummy initctl
echo "Diverting initctl..."
lxc exec $CONTAINER -- dpkg-divert --local --rename --add /sbin/initctl
echo "Linking..."
lxc exec $CONTAINER -- ln -sf /bin/true /sbin/initctl

# lxc exec $CONTAINER -- apt install -y ubuntu-desktop^ ubuntu-live^
# lxc exec $CONTAINER -- apt install -y --no-install-recommends \
lxc exec $CONTAINER -- apt install -y \
  apt-clone \
  archdetect-deb \
  binutils \
  crda \
  cryptsetup \
  cryptsetup-bin \
  dmraid \
  dpkg-repack \
  ecryptfs-utils \
  gir1.2-appindicator3-0.1 \
  gir1.2-json-1.0 \
  gir1.2-timezonemap-1.0 \
  gir1.2-xkl-1.0 \
  gparted \
  iw \
  keyutils \
  kpartx \
  kpartx-boot \
  language-pack-en \
  language-pack-en-base \
  libatkmm-1.6-1 \
  libcairomm-1.0-1 \
  libcryptsetup4 \
  libdebian-installer4 \
  libdevmapper-event1.02.1 \
  libdmraid1.0.0.rc16 \
  libecryptfs0 \
  libglibmm-2.4-1c2a \
  libgtkmm-2.4-1c2a \
  libnss3-1d \
  libpangomm-1.4-1 \
  libsigc++-2.0-0c2a \
  libtimezonemap1 \
  lvm2 \
  pptp-linux \
  python3-cairo \
  python3-gi-cairo \
  python3-icu \
  python3-pam \
  rdate \
  sbsigntool \
  ubiquity \
  ubiquity-casper \
  ubiquity-frontend-gtk \
  ubiquity-ubuntu-artwork \
  watershed \
  wireless-regdb \
  xserver-xorg \
  gnome-themes-standard \
  lightdm

lxc exec $CONTAINER -- rm /usr/sbin/policy-rc.d

echo "Removing diversions..."
lxc exec $CONTAINER -- cp /bin/running-in-container.distrib /bin/running-in-container
lxc exec $CONTAINER -- cp /sbin/initctl.distrib /sbin/initctl

lxc exec $CONTAINER -- dpkg-divert --remove /bin/running-in-container
lxc exec $CONTAINER -- dpkg-divert --remove /sbin/initctl

# clean up

lxc exec $CONTAINER -- apt-get clean
lxc exec $CONTAINER -- rm /var/lib/dbus/machine-id
lxc exec $CONTAINER -- rm /etc/init/console.override
lxc exec $CONTAINER -- rm /etc/init/tty1.override
lxc exec $CONTAINER -- rm /etc/init/tty2.override
lxc exec $CONTAINER -- rm /etc/init/tty3.override
lxc exec $CONTAINER -- rm /etc/init/tty4.override
# this will be recreated
lxc exec $CONTAINER -- rm /etc/network/interfaces.d/eth0.cfg

kversion=$(lxc exec $CONTAINER -- ls /boot/ | grep vmlinuz | grep -v efi | tail -1 | sed s@vmlinuz-@@)

lxc file pull $CONTAINER/boot/vmlinuz-${kversion} ${CD}/${FS_DIR}/vmlinuz
lxc file pull $CONTAINER/boot/initrd.img-${kversion} ${CD}/${FS_DIR}/initrd.img

lxc exec $CONTAINER -- dpkg-query -W --showformat='${Package} ${Version}\n' | sort > ${CD}/${FS_DIR}/filesystem.manifest

comm -2 -3 ${CD}/${FS_DIR}/filesystem.manifest ${CD}/${FS_DIR}/filesystem-desktop.manifest > ${CD}/${FS_DIR}/filesystem-remove.manifest

lxc stop $CONTAINER

cat > ${CD}/boot/grub/grub.cfg << EOF
if loadfont /boot/grub/font.pf2 ; then
    set gfxmode=auto
    insmod efi_gop
    insmod efi_uga
    insmod gfxterm
    terminal_output gfxterm
fi

set default="0"
set timeout=10

menuentry "Automated Install" {
  linux /casper/vmlinuz boot=casper only-ubiquity automatic-ubiquity noprompt quiet splash file=/cdrom/preseed/posm-full.seed ip=frommedia
  initrd /casper/initrd.img
}

menuentry "Install" {
  linux /casper/vmlinuz boot=casper only-ubiquity noprompt quiet splash file=/cdrom/preseed/posm.seed ip=frommedia
  initrd /casper/initrd.img
}
EOF

# export from LXC in order to get correct UID/GIDs
lxc publish $CONTAINER --alias $CONTAINER
lxc image export $CONTAINER ${CONTAINER}.tar.gz
lxc image delete $CONTAINER
sudo rm -rf rootfs/
sudo tar zxf ${CONTAINER}.tar.gz rootfs/
rm ${CONTAINER}.tar.gz

cat > ${CD}/${FS_DIR}/postinstall.sh <<EOF
#!/bin/sh

chroot /target mount -t proc proc /proc
chroot /target mount -t sysfs sysfs /sys
chroot /target mount -t securityfs securityfs /sys/kernel/security
mount --bind /dev /target/dev
mount --bind /run /target/run

awk '{print \$1}' /cdrom/casper/filesystem-remove.manifest | xargs chroot /target apt-get purge -y
chroot /target apt-get autoremove
# TODO split wifi into package installation and configuration
chroot /target /root/posm-build/kickstart/scripts/bootstrap.sh wifi captive
EOF

chmod +x ${CD}/${FS_DIR}/postinstall.sh

cat > ${CD}/preseed/posm.seed <<EOF
### Localization
d-i debian-installer/locale string en_US.UTF-8

### Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string Etc/UTC
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string us.pool.ntp.org

### Account setup
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password \$1\$foobar12\$1XX5fPEUg/6I1MhChN1ad1

# set hostname
d-i netcfg/get_hostname string posm
d-i netcfg/get_domain string io

### Boot loader installation
# workaround for NUC console driver (prevents requiring HDMI to be re-plugged
# periodically)
d-i debian-installer/add-kernel-opts string consoleblank=0

### Finishing up the installation
d-i finish-install/reboot_in_progress note

ubiquity ubiquity/summary note
ubiquity ubiquity/success_command string /cdrom/casper/postinstall.sh
ubiquity languagechooser/language-name string "English"
EOF

cat > ${CD}/preseed/posm-full.seed <<EOF
### Localization
d-i debian-installer/locale string en_US.UTF-8

### Keyboard selection.
# Disable automatic (interactive) keymap detection.
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/layoutcode string us

### Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string Etc/UTC
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string us.pool.ntp.org

### Partitioning
# d-i preseed/early_command string umount /media
# d-i partman/installation_medium_mounted note
d-i partman/unmount_active boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i partman/default_filesystem string ext4
d-i partman/mount_style select label
# d-i partman/mount_style select uuid
d-i partman-auto/method string regular

### Account setup
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password \$1\$foobar12\$1XX5fPEUg/6I1MhChN1ad1

# set hostname
d-i netcfg/get_hostname string posm
d-i netcfg/get_domain string io

### Boot loader installation
# workaround for NUC console driver (prevents requiring HDMI to be re-plugged
# periodically)
d-i debian-installer/add-kernel-opts string consoleblank=0

### Finishing up the installation
d-i finish-install/reboot_in_progress note

ubiquity ubiquity/summary note
ubiquity ubiquity/reboot boolean true
ubiquity ubiquity/success_command string /cdrom/casper/postinstall.sh
ubiquity languagechooser/language-name string "English"
EOF

sudo mksquashfs rootfs ${CD}/${FS_DIR}/filesystem.${FORMAT} -noappend
sudo chown $(whoami):$(whoami) ${CD}/${FS_DIR}/filesystem.${FORMAT}
echo -n $(sudo du -s --block-size=1 rootfs | tail -1 | awk '{print $1}') > ${CD}/${FS_DIR}/filesystem.size
find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt > ${CD}/md5sum.txt

sudo rm -rf rootfs

sudo grub-mkrescue -o ~/live-cd.iso ${CD}
sudo chown $(whoami):$(whoami) ~/live-cd.iso

rm -rf $WORK
lxc delete $CONTAINER --force
