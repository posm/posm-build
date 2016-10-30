# POSM Build

USB Auto-Build Process (OS X)
=============================

1. Connect the NUC's Ethernet port to an internet-connected LAN.
2. Download https://s3-us-west-2.amazonaws.com/posm/posm-install-24180cb-fat.tar and unzip locally (`tar xf posm-install-24180cb-fat.tar` will produce `posm-install-24180cb.img`).
3. Insert a USB stick
4. Unmount if necessary `diskutil unmountDisk /dev/<USB>`. (`diskutil list` will show available devices on OS X)
5. [Image it to a USB
  drive](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx).
  (`sudo dd if=posm-install-24180cb.img of=/dev/r<USB> bs=1m` or similar). It will remount as `POSM` when done.
6. Update `/Volumes/POSM/posm-build`: `git pull`
7. _(optional)_ Put any local settings in `posm-build/kickstart/etc/settings.local`.
8. Boot to the USB stick by pressing `F10` and pick `Install POSM Server` from the menu.
9. Watch it reboot. After the system has restarted, the POSM bootstrap installation will automatically begin.
10. Log in as `root` / `posm` and `tail -f bootstrap.log` to check the installation status. This may take a while.
11. Watch it reboot once installation is complete.

Steps on Linux are similar, although the device name will differ.

If you are installing POSM onto a bare drive (one that has never been partitioned), you will
encounter a "Cannot mount CD-ROM" error. You can follow one of the workarounds documented in
https://github.com/AmericanRedCross/posm/issues/116 or (this is one of them), plug the installation
media into one of the rear USB ports and an empty (formatted) USB stick into the front. Yeah, weird.

Interim Manual Build Process (for Virtual Machines)
============================

1. Install [Ubuntu 14.04 LTS minimal server](http://www.ubuntu.com/download/server) however you like
  * See details below for [Ubuntu Server Install Details for NUC](#ubuntu-server-install-details-for-nuc)
2. Become `root`. If you use `sudo`, use `sudo -i`.
3.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
4. Put any local settings in `/root/etc/settings.local` (see `/root/etc/settings`)
  * Important ones for development are the ones that involve DNS and URLs:
    * `posm_hostname="whateveryouwant"`
    * `posm_domain="yourdomain.foo"`
    * `posm_fqdn="whateveryouwant.yourdomain.foo"`
    * `posm_base_url="http://${posm_fqdn}"`
    * `fp_api_base_url="${posm_base_url}/fp"`
    * `fp_tile_base_url="${posm_base_url}/fp-tiler"`
5. `/root/scripts/bootstrap.sh base virt nodejs ruby gis mysql postgis nginx osm fieldpapers omk tl carto tessera admin samba` (note: `wifi` is omitted from this list)
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

SuperPOSM
=========

To add SuperPOSM capabilities (OpenDroneMap + GeoTIFF processing), add `docker redis opendronemap
imagery` to the list of modules being deployed.

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
| `/tiles/{style}` | [tessera](https://github.com/mojodna/tessera) | http://127.0.0.1:8082 |
| `/fp` | [Field Papers](https://github.com/fieldpapers/fp-web) | http://127.0.0.1:3000/fp |
| `/fp-tiler` | [Field Papers Tiler](https://github.com/fieldpapers/fp-tiler) | http://127.0.0.1:8080/fp-tiler |
| `/fp-tasks` | [Field Papers Tasks](https://github.com/fieldpapers/fp-tasks) | http://127.0.0.1:8081/fp-tasks |
| `/omk` | [OpenMapKit Server](https://github.com/AmericanRedCross/OpenMapKitServer) | http://127.0.0.1:3210 |
| `/osm` | [OpenStreetMap-website](https://github.com/AmericanRedCross/openstreetmap-website) | http://127.0.0.1:9000 |
