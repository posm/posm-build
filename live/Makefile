ARCH ?= amd64
DIST ?= bionic
DEBIAN_FRONTEND = noninteractive
DEBCONF_NONINTERACTIVE_SEEN = true
GIT_REPO ?= "https://github.com/posm/posm-build"
GIT_BRANCH ?= "master"

default: posm.iso

# can't run apt in parallel
.NOTPARALLEL:

container:
	lxc launch ubuntu:$(DIST)/$(ARCH) -p default \
		-c security.privileged=true \
		-c security.nesting=true \
		-c environment.DEBIAN_FRONTEND=noninteractive \
		-c environment.DEBCONF_NONINTERACTIVE_SEEN=true \
		-c linux.kernel_modules="overlay, nf_nat, aufs" | \
		tail -1 | cut -d " " -f 2 > $@
	sleep 5
	lxc exec $$(cat container) -- apt update
	lxc exec $$(cat container) -- apt install --no-install-recommends -y linux-generic grub-pc secureboot-db grub2-common mokutil efibootmgr libefiboot1

base: container
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

postgis: nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

nginx: base nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

osm: nodejs ruby postgis nginx
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

fieldpapers: nodejs ruby postgis
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

clusterodm: nodeodm
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

nodeodm: docker nodejs
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

odm-worker: nodeodm
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

webodm: nginx nodejs clusterodm nodeodm postgis redis
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

posm-auth: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

odk-central: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

replay-tool: base
	lxc exec $$(cat container) -- /root/posm-build/kickstart/scripts/bootstrap.sh $@
	lxc snapshot $$(cat container) $@
	touch $@

posm-core: gis nginx osm fieldpapers omk tl carto tessera admin samba blink1 influxdb telegraf posm-auth replay-tool odk-central

posm: posm-core wifi
	lxc exec $$(cat container) -- systemctl stop docker
	lxc exec $$(cat container) -- apt-get autoremove -y
	lxc exec $$(cat container) -- apt-get clean
	echo 'root:posm' | lxc exec $$(cat container) -- chpasswd
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/scripts /root/scripts
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/etc /root/etc
	lxc exec $$(cat container) -- rm -f /etc/ssh/ssh_host_*
	lxc exec $$(cat container) -- rm -f /var/lib/dbus/machine-id
	lxc exec $$(cat container) -- userdel -r ubuntu || true
	lxc delete $$(cat container)/$@ || true
	lxc snapshot $$(cat container) $@
	touch $@

superposm: posm-core docker redis webodm imagery wifi
	lxc exec $$(cat container) -- systemctl stop docker
	lxc exec $$(cat container) -- apt-get autoremove -y
	lxc exec $$(cat container) -- apt-get clean
	echo 'root:posm' | lxc exec $$(cat container) -- chpasswd
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/scripts /root/scripts
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/etc /root/etc
	lxc exec $$(cat container) -- rm -f /etc/ssh/ssh_host_*
	lxc exec $$(cat container) -- rm -f /var/lib/dbus/machine-id
	lxc exec $$(cat container) -- userdel -r ubuntu || true
	lxc exec $$(cat container) -- hostnamectl set-hostname posm
	lxc delete $$(cat container)/$@ || true
	lxc snapshot $$(cat container) $@
	touch $@

posm-aux: odm-worker blink1 influxdb telegraf nginx
	lxc exec $$(cat container) -- systemctl stop docker
	lxc exec $$(cat container) -- apt-get autoremove -y
	lxc exec $$(cat container) -- apt-get clean
	echo 'root:posm' | lxc exec $$(cat container) -- chpasswd
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/scripts /root/scripts
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/etc /root/etc
	lxc exec $$(cat container) -- rm -f /etc/ssh/ssh_host_*
	lxc exec $$(cat container) -- rm -f /var/lib/dbus/machine-id
	lxc exec $$(cat container) -- userdel -r ubuntu || true
	lxc exec $$(cat container) -- hostnamectl set-hostname posm-aux
	lxc delete $$(cat container)/$@ || true
	lxc snapshot $$(cat container) $@
	touch $@

cdrom: bionic-live-server-amd64.iso
	mkdir -p cdrom
	7z x -o$@ $< dists/ pool/
	sudo chown -R root:root $@
	sudo chmod -R a+rx $@

posm.tgz: posm cdrom
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -f /etc/apt/sources.list
	lxc exec $$(cat container) -- touch /etc/apt/sources.list
	lxc exec $$(cat container) -- add-apt-repository -n "deb file:///cdrom/ bionic main restricted"
	sudo tar cf - -p ./cdrom -C /var/lib/lxd/containers/$$(cat container)/rootfs . | pigz > $@
	sudo chown $$(whoami):$$(whoami) $@

superposm.tgz: superposm cdrom
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -f /etc/apt/sources.list
	lxc exec $$(cat container) -- touch /etc/apt/sources.list
	lxc exec $$(cat container) -- add-apt-repository -n "deb file:///cdrom/ bionic main restricted"
	sudo tar cf - -p ./cdrom -C /var/lib/lxd/containers/$$(cat container)/rootfs . | pigz > $@
	sudo chown $$(whoami):$$(whoami) $@

posm-aux.tgz: posm-aux cdrom
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -rf /etc/apt/sources.list.d/
	lxc exec $$(cat container) -- rm -f /etc/apt/sources.list
	lxc exec $$(cat container) -- touch /etc/apt/sources.list
	lxc exec $$(cat container) -- add-apt-repository -n "deb file:///cdrom/ bionic main restricted"
	sudo tar cf - -p ./cdrom -C /var/lib/lxd/containers/$$(cat container)/rootfs . | pigz > $@
	sudo chown $$(whoami):$$(whoami) $@

bionic-live-server-amd64.iso:
	curl -sfL http://cdimage.ubuntu.com/ubuntu-server/bionic/daily-live/current/bionic-live-server-amd64.iso -o $@

posm.iso: posm.tgz bionic-live-server-amd64.iso
	ROOTFS=$$(readlink -f $<) make -C subiquity $@

superposm.iso: superposm.tgz bionic-live-server-amd64.iso
	ROOTFS=$$(readlink -f $<) make -C subiquity $@

posm-aux.iso: posm-aux.tgz bionic-live-server-amd64.iso
	ROOTFS=$$(readlink -f $<) POSM_HOSTNAME=posm-aux make -C subiquity $@

clean:
	test -f container && lxc delete $$(cat container) --force || true
	sudo rm -rf cdrom
	rm -rf admin base blink1 carto container docker fieldpapers gis imagery influxdb nginx nodejs omk opendronemap osm posm postgis redis ruby samba telegraf tessera tl wifi odm-worker clusterodm nodeodm webodm posm.tgz posm.iso posm-aux posm-aux.tgz posm-aux.iso superposm superposm.tgz superposm.iso
