# POSM Build

USB Auto-Build Process (OS X)
=============================

1. Download https://s3-us-west-2.amazonaws.com/posm/posm-install-24180cb-fat.tar
2. Insert a USB stick
3. Unmount if necessary `diskutil unmountDisk /dev/<USB>`. (`diskutil list` will show available devices on OS X)
4. [Image it to a USB
  drive](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx).
  (`sudo dd if=ubuntu-14.04.3-server-amd64.img of=/dev/r<USB> bs=1m` or similar). It will remount as `POSM` when done.
5. Update `/Volumes/POSM/posm-build`: `git pull`
6. _(optional)_ Put any local settings in `posm-build/kickstart/etc/settings.local`.
7. Boot to the USB stick by pressing `F10` and pick `Install POSM Server` from the menu.
9. Watch it reboot. After the system has restarted, the POSM bootstrap installation will automatically begin.
10. Log in as `root` / `posm` and `tail -f bootstrap.log` to check the installation status. This may take a while.
11. Watch it reboot once installation is complete.

Steps on Linux are similar, although the device name will differ.

Interim Manual Build Process (for Virtual Machines)
============================

1. Install [Ubuntu 14.04 LTS minimal server](http://www.ubuntu.com/download/server) however you like
  * See details below for [Ubuntu Server Install Details for NUC](#ubuntu-server-install-details-for-nuc)
2. Become `root`
3.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
4. Put any local settings in `/root/etc/settings.local` (see `/root/etc/settings`)
  * Important ones for development are the ones that involve DNS and URLs:
    * `posm_domain="yourdomain.foo"`
    * `posm_hostname="whateveryouwant.yourdomain.foo"`
5. `/root/scripts/bootstrap.sh base virt nodejs ruby gis mysql postgis nginx osm fieldpapers omk mbtiles carto tessera id` (note: `wifi` is omitted from this list)
6. `/root/scripts/bootstrap.sh demo_data`, if you want it

Interim PXE Build Process
=========================

1. Create a PXE boot server for Ubuntu 14.04 LTS
 * Installing to a NUC using PXE seems problematic due to the install happening in Legacy BIOS mode, not UEFI
2. Put this entire repo at `/posm` on your Kickstart / PXE web server
3. PXE boot as approriate to use the `POSM_Server.cfg` preseed, for example, add the following on the kernel line: `auto=true url=http://ks/posm/kickstart/POSM_Server.cfg`
  * The `POSM_Server.cfg` preseed expects that your kickstart server has a hostname of `ks`, and you have a Ubuntu package cache (e.g. `apt-cacher-ng`) at `http://apt-proxy:3142`.
  * Edit Ubuntu cache/proxy in `mirror/http/proxy` (set to empty string to use default, do not just comment out)
  * Edit PXE server hostnames in `partman/early_command` and `preseed/late_command`

Hardware Requirements
=====================
* At least 2GB RAM, 8GB preferred
* At least a 30GB drive
* A compatible wireless adapter, for running a Software Access Point ("Captive Portal", `hostapd`)

Configuration & Ports
=====================

Configuration is achieved by putting local settings into a `settings.local` file. See [etc/settings](kickstart/etc/settings) for available settings.  Ports for individual services are set here for example.

Default Ports & URLs
--------------------

| URI | Service | Internal URL |
| --- | --- | --- | --- |
| `/id` | [OSM iD](https://github.com/AmericanRedCross/iD) | http://127.0.0.1/iD |
| `/tiles/{style}` | [tessera](https://github.com/mojodna/tessera) | http://127.0.0.1:8082 |
| `/fp` | [Field Papers](https://github.com/fieldpapers/fp-web) | http://127.0.0.1:3000/fp |
| `/fp-tiler` | [Field Papers Tiler](https://github.com/fieldpapers/fp-tiler) | http://127.0.0.1:8080/fp-tiler |
| `/fp-tasks` | [Field Papers Tasks](https://github.com/fieldpapers/fp-tasks) | http://127.0.0.1:8081/fp-tasks |
| `/omk` | [OpenMapKit Server](https://github.com/AmericanRedCross/OpenMapKitServer) | http://127.0.0.1:3210 |
| `/api` | [OpenStreetMap-website](https://github.com/AmericanRedCross/openstreetmap-website) | http://127.0.0.1:9000 |
