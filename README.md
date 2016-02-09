# POSM Build

USB Auto-Build Process
======================
1. Create a Ubuntu 14.04 server install USB stick as usual (normal Ubuntu `amd64`/`x86_64` server ISO, not a `mini.iso`)
  * [How to create a bootable USB stick on Ubuntu](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-ubuntu)
  * [How to create a bootable USB stick on Windows](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-windows)
  * [How to create a bootable USB stick on OS X](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx)
2. Mount the USB drive
3. Clone this project to the root drive of the USB stick
4. Copy `posm-build/grub/grub.cfg` to `grub/grub.cfg` (on the USB stick)
5. (optional) Put any local settings in `posm-build/kickstart/etc/settings.local`
6. Boot the USB stick and pick `Install POSM Server` from the menu
7. Respond to partitioning-related prompts
8. Watch it reboot
9. Log in as `root` / `posm` and `tail -f bootstrap.log` to check status. This may take a while.

USB Auto-Build Process (OS X)
=============================
1. Download https://s3-us-west-2.amazonaws.com/posm/ubuntu-14.04.3-server-amd64.img
2. Unmount Disk `diskutil unmountDisk /dev/<USB>`
3. [Image it to a USB
  drive](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx)
  (`sudo dd if=ubuntu-14.04.3-server-amd64.img of=/dev/r<USB> bs=1m` or similar).
4. Clone this project to the root drive of the USB stick
5. Copy `posm-build/grub/grub.cfg` to `boot/grub/grub.cfg` (on the USB stick)
6. (optional) Put any local settings in `posm-build/kickstart/etc/settings.local`
7. Boot the USB stick and pick `Install POSM Server` from the menu
8. Respond to partitioning-related prompts
9. Watch it reboot
10. Log in as `root` / `posm` and `tail -f bootstrap.log` to check status. This may take a while.

Interim Manual Build Process
============================

1. Install [Ubuntu 14.04 LTS minimal server](http://www.ubuntu.com/download/server) however you like
  * See details below for [Ubuntu Server Install Details for NUC](#ubuntu-server-install-details-for-nuc)
2. Become `root`
3.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
4. Put any local settings in `/root/etc/settings.local` (see `/root/etc/settings`)
  * Important ones for development are the ones that involve DNS and URLs:
    * `posm_domain="yourdomain.foo"`
    * `posm_hostname="whateveryouwant.yourdomain.foo"`
    * `posm_base_url="http://$posm_hostname"`
    * `fp_api_base_url="${posm_base_url}/fp"`
    * `fp_tile_base_url="${posm_base_url}/fp-tiler"`
5. `/root/scripts/bootstrap.sh base virt wifi nodejs ruby gis osm mysql postgis nginx fieldpapers omk mbtiles carto tessera id`
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

Ubuntu Server Install Details for NUC
=====================================
 * Please install Ubuntu on the NUC in [UEFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) mode!
   * To do this, use a normal Ubuntu `amd64`/`x86_64` server ISO (not a `mini.iso`) on a USB drive
   * [How to create a bootable USB stick on Ubuntu](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-ubuntu)
   * [How to create a bootable USB stick on Windows](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-windows)
   * [How to create a bootable USB stick on OS X](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx)
 * If Ubuntu says it cannot detect the CD-ROM:
   * `Alt-F2` to switch console
   * `Enter` to active the console
   * Type `umount /media`
   * `Alt-F1` to return to installer, and try to detect again
 * Set the hostname to `posm.lan`
 * Set the local user name to `posm`
 * Set the time zone to `UTC` (press `End` key to get to the bottom of the list)
 * (Optional) Use LVM partitioning using only 30GB of space (so you can allocate remainder for data later)
 * No automatic updates (turn them on if the unit isn't going to the field)
