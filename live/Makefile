ARCH ?= amd64
DIST ?= trusty
DEBIAN_FRONTEND = noninteractive
DEBCONF_NONINTERACTIVE_SEEN = true
GIT_REPO ?= "https://github.com/posm/posm-build"
GIT_BRANCH ?= "master"

default: live-cd.iso

# can't run apt in parallel
.NOTPARALLEL:

ubuntu-14.04-desktop-amd64.iso:
	curl -sLf http://releases.ubuntu.com/14.04/ubuntu-14.04.5-desktop-amd64.iso -o $@

deps:
	sudo apt update
	sudo apt install -y grub2 xorriso squashfs-tools p7zip
	touch $@

cd/.disk cd/boot cd/dists cd/EFI cd/pool: ubuntu-14.04-desktop-amd64.iso deps
	7z x $< -o$$(dirname $@) $(subst cd/,,$@)

container:
	lxc launch ubuntu:$(DIST)/$(ARCH) -p default -p docker \
		-c security.privileged=true \
		-c environment.DEBIAN_FRONTEND=noninteractive \
		-c environment.DEBCONF_NONINTERACTIVE_SEEN=true \
		-c linux.kernel_modules="overlay, nf_nat, aufs" | \
		tail -1 | cut -d " " -f 2 > $@
	sleep 5

container-init: container
	lxc exec $$(cat container) -- apt update
	lxc exec $$(cat container) -- apt upgrade -y
	lxc exec $$(cat container) -- apt install -y ubuntu-standard
	lxc exec $$(cat container) -- apt purge -y cloud-init
	lxc snapshot $$(cat container) $@
	touch $@

base: container-init
	lxc exec $$(cat container) -- apt install -y --no-install-recommends git
	lxc exec $$(cat container) -- git clone $(GIT_REPO) -b $(GIT_BRANCH)
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

nodejs: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

ruby: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

gis: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

mysql: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

postgis: nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

nginx: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

osm: nodejs ruby postgis nginx
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

fieldpapers: nodejs ruby mysql
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

omk: docker
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

tl: nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

carto: postgis tessera gis osm
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

tessera: nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

admin: nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

samba: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

blink1: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

docker: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

redis: docker
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

opendronemap: redis
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

imagery: redis
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

wifi: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

influxdb: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

telegraf: influxdb
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

posm: base nodejs ruby gis mysql postgis nginx osm fieldpapers omk tl carto tessera admin samba blink1 docker redis opendronemap imagery wifi influxdb telegraf
	lxc exec $$(cat container) -- apt upgrade -y
	lxc exec $$(cat container) -- apt-get autoremove -y
	lxc snapshot $$(cat container) $@
	touch $@

cd/casper/filesystem-desktop.manifest: posm
	mkdir -p $$(dirname $@)
	lxc exec $$(cat container) -- \
		dpkg-query -W --showformat='$${Package} $${Version}\n' | sort > $@

postinstall: cd/casper/filesystem-desktop.manifest
	lxc exec $$(cat container) -- \
		apt install -y --no-install-recommends casper

	# the shipped version of running-in-container returns false when initctl is
	# also diverted, as the first check uses upstart and fails because the
	# service being queries intentionally wasn't started.
	echo "Diverting running-in-container..."
	lxc exec $$(cat container) -- \
		dpkg-divert --local --rename --add /bin/running-in-container

	echo "Stubbing /bin/running-in-container..."
	lxc file push --uid=0 --gid=0 --mode=755 running-in-container $$(cat container)/bin/running-in-container

	# https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt
	echo "Creating policy-rc.d..."
	lxc file push --uid=0 --gid=0 --mode 755 policy-rc.d $$(cat container)/usr/sbin/policy-rc.d

	# Stub initctl to prevent subsequently-installed services from installing
	echo "Diverting initctl..."
	lxc exec $$(cat container) -- \
	  dpkg-divert --local --rename --add /sbin/initctl

	echo "Linking replacement..."
	lxc exec $$(cat container) -- \
	  ln -sf /bin/true /sbin/initctl

	# This is the minimal (or close to it) list of packages needed to bring up
	# the casper GUI within X Windows. --no-install-recommends works, but drops
	# some of the niceties like wallpaper and menu bar items.
	#
	# Including ubuntu-desktop^ and ubuntu-live^ (which are the tasks installed
	# on a normal desktop live image) makes the installation equally nice with
	# the added benefit of being a working live distro at the expense of a
	# larger download.
	#
	# If we decide that this is actually valuable, make sure that it can be
	# logged into or that it logs in automatically (because it currently
	# can't be as a result of the ubuntu user not having a password).
	#
	# These packages are all uninstalled during the postinstall phase, as we
	# have no use for a GUI on a running POSM.
	lxc exec $$(cat container) -- \
	 	apt install -y \
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

	lxc exec $$(cat container) -- \
	  rm /usr/sbin/policy-rc.d

	echo "Removing diversions..."
	lxc exec $$(cat container) -- \
	 	cp /bin/running-in-container.distrib /bin/running-in-container
	lxc exec $$(cat container) -- \
	 	cp /sbin/initctl.distrib /sbin/initctl
	lxc exec $$(cat container) -- \
		dpkg-divert --remove /bin/running-in-container
	lxc exec $$(cat container) -- \
		dpkg-divert --remove /sbin/initctl

	# clean up
	lxc exec $$(cat container) -- \
		apt-get clean
	lxc exec $$(cat container) -- \
	  rm -f /etc/init/console.override
	lxc exec $$(cat container) -- \
	  rm -f /etc/init/tty1.override
	lxc exec $$(cat container) -- \
	  rm -f /etc/init/tty2.override
	lxc exec $$(cat container) -- \
	  rm -f /etc/init/tty3.override
	lxc exec $$(cat container) -- \
	  rm -f /etc/init/tty4.override

	# this will be recreated
	lxc exec $$(cat container) -- \
	  rm /etc/network/interfaces.d/eth0.cfg

	touch $@

cd/casper/vmlinuz: posm
	mkdir -p $$(dirname $@)
	lxc file pull $$(cat container)/boot/vmlinuz-$$(lxc exec $$(cat container) -- ls /boot/ | grep vmlinuz | grep -v efi | tail -1 | sed s@vmlinuz-@@) $@

cd/casper/initrd.img: posm
	mkdir -p $$(dirname $@)
	lxc file pull $$(cat container)/boot/initrd.img-$$(lxc exec $$(cat container) -- ls /boot/ | grep vmlinuz | grep -v efi | tail -1 | sed s@vmlinuz-@@) $@

cd/casper/filesystem.manifest: postinstall
	mkdir -p $$(dirname $@)
	lxc exec $$(cat container) -- \
		dpkg-query -W --showformat='$${Package} $${Version}\n' | sort > $@

cd/casper/filesystem-remove.manifest: cd/casper/filesystem.manifest cd/casper/filesystem-desktop.manifest
	mkdir -p $$(dirname $@)
	comm -2 -3 $^ > $@

cd/boot/grub/grub.cfg: grub.cfg cd/boot
	cp $< $@

rootfs: postinstall
	ln -sf /var/lib/lxd/containers/$$(cat container).zfs/rootfs

cd/casper/postinstall.sh: postinstall.sh
	mkdir -p $$(dirname $@)
	cp $< $@
	chmod +x $@

cd/preseed/posm.seed: posm.seed
	mkdir -p $$(dirname $@)
	cp $< $@

cd/preseed/posm-full.seed: posm-full.seed
	mkdir -p $$(dirname $@)
	cp $< $@

cd/casper/filesystem.squashfs: rootfs deps cd/casper/vmlinuz cd/casper/initrd.img cd/casper/filesystem.manifest
	lxc stop $$(cat container) || true
	mkdir -p $$(dirname $@)
	sudo mksquashfs $</ $@ -noappend
	sudo chown $$(whoami):$$(whoami) $@

cd/casper/filesystem.size: rootfs
	mkdir -p $$(dirname $@)
	echo -n $$(sudo du -s --block-size=1 $< | tail -1 | awk '{print $$1}') > $@

# in reality this depends on every under cd/
cd/md5sum.txt: cd/casper/filesystem.squashfs
	mkdir -p $$(dirname $@)
	find cd -type f -print0 | xargs -0 md5sum | sed "s@ cd@ .@" | grep -v md5sum.txt > $@

live-cd.iso: cd/.disk cd/boot cd/dists cd/EFI cd/casper/filesystem.squashfs cd/casper/filesystem.size cd/md5sum.txt cd/preseed/posm.seed cd/preseed/posm-full.seed cd/casper/postinstall.sh cd/boot/grub/grub.cfg cd/casper/filesystem.manifest cd/casper/filesystem-desktop.manifest cd/casper/filesystem-remove.manifest cd/casper/vmlinuz cd/casper/initrd.img cd/pool deps
	sudo grub-mkrescue -o $@ cd/
	sudo chown $$(whoami):$$(whoami) $@

clean:
	test -f container && lxc delete $$(cat container) --force || true
	rm -rf admin base blink1 carto cd/ container container-init deps docker fieldpapers gis imagery influxdb live-cd.iso mysql nginx nodejs omk opendronemap osm posm postgis postinstall redis rootfs ruby samba telegraf tessera tl wifi
