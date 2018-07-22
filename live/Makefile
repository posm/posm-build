ARCH ?= amd64
DIST ?= bionic
DEBIAN_FRONTEND = noninteractive
DEBCONF_NONINTERACTIVE_SEEN = true
GIT_REPO ?= "https://github.com/posm/posm-build"
GIT_BRANCH ?= "master"

default: posm.tgz

# can't run apt in parallel
.NOTPARALLEL:

container:
	lxc launch ubuntu:$(DIST)/$(ARCH) -p default -p docker \
		-c security.privileged=true \
		-c environment.DEBIAN_FRONTEND=noninteractive \
		-c environment.DEBCONF_NONINTERACTIVE_SEEN=true \
		-c linux.kernel_modules="overlay, nf_nat, aufs" | \
		tail -1 | cut -d " " -f 2 > $@
	sleep 5
	lxc exec $$(cat container) -- apt install --no-install-recommends -y linux-generic

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

posm: base nodejs ruby gis mysql postgis nginx osm fieldpapers omk tl carto tessera admin samba blink1 docker redis opendronemap imagery influxdb telegraf wifi
	lxc exec $$(cat container) -- apt-get autoremove -y
	lxc exec $$(cat container) -- apt-get clean
	echo 'root:posm' | lxc exec $$(cat container) -- chpasswd
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/scripts /root/scripts
	lxc exec $$(cat container) -- ln -sf /root/posm-build/kickstart/etc /root/etc
	lxc exec $$(cat container) -- rm -f /etc/ssh/ssh_host_*
	lxc exec $$(cat container) -- rm -f /var/lib/dbus/machine-id
	lxc exec $$(cat container) -- userdel -r ubuntu
	lxc delete $$(cat container)/$@ || true
	lxc snapshot $$(cat container) $@
	touch $@

posm.tgz: posm
	lxc stop $$(cat container) || true
	sudo tar cf - -p -C /var/lib/lxd/containers/$$(cat container)/rootfs . | pigz > $@
	sudo chown $$(whoami):$$(whoami) $@

clean:
	test -f container && lxc delete $$(cat container) --force || true
	rm -rf admin base blink1 carto container docker fieldpapers gis imagery influxdb mysql nginx nodejs omk opendronemap osm posm postgis redis ruby samba telegraf tessera tl wifi posm.tgz