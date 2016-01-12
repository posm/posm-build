# posm-build

Interim Manual Build Process
============================

 1. Install [Ubuntu 14.04 LTS minimal server](http://www.ubuntu.com/download/server) however you like
   * For NUC deployment, install via USB
   * [How to create a bootable USB stick on Ubuntu](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-ubuntu)
   * [How to create a bootable USB stick on Windows](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-windows)
   * [How to create a bootable USB stick on OS X](http://www.ubuntu.com/download/desktop/create-a-usb-stick-on-mac-osx)
 2.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
 3. Put any local settings in `/root/etc/settings.local` (see `/root/etc/settings`)
   * Important ones for now are the ones that involve DNS and URLs:
      * `posm_base_url="http://whateveryouwant.yourdomain.foo"`
      * `fp_api_base_url="${posm_base_url}/fp"`
      * `fp_tile_base_url="${posm_base_url}/fp-tiler"`
 4. `/root/scripts/bootstrap.sh base virt wifi nodejs ruby gis osm mysql postgis nginx fieldpapers omk mbtiles tessera macrocosm id`
 5. `/root/scripts/bootstrap.sh demo_data`, if you want it

Interim PXE Build Process
=========================

 1. Create a PXE boot server for Ubuntu 14.04 LTS
 2. Put this enitre repo at the root of your Kickstart / PXE web server
 3. PXE boot as approriate to use the `POSM_Server.cfg` preseed, for example, add the following on the kernel line: `auto=true url=http://ks/kickstart/POSM_Server.cfg`

Configuration & Ports
=====================

Configuration is achieved by putting local settings into a `settings.local` file. See [etc/settings](kickstart/etc/settings) for available settings.  Ports for individual services are set here for example.

Default Ports & URLs
--------------------

| URI | Service | Internal URL |
| --- | --- | --- | --- |
| `/id` | [OSM iD](https://github.com/AmericanRedCross/iD) | http://127.0.0.1/iD |
| `/tiles/{style}` | [tessera](https://github.com/mojodna/tessera) | http://127.0.0.1:8082 |
| `/fp-tiler` | [Field Papers Tiler](https://github.com/fieldpapers/fp-tiler) | http://127.0.0.1:8080/fp-tiler |
| `/fp-tasks` | [Field Papers Tasks](https://github.com/fieldpapers/fp-tasks) | http://127.0.0.1:8081/fp-tasks |
| `/omk` | [OpenMapKit Server](https://github.com/AmericanRedCross/OpenMapKitServer) | http://127.0.0.1:3210 |
| `/api` | [Macrocosm](https://github.com/AmericanRedCross/macrocosm) | http://127.0.0.1:4000 |

Ubuntu Server Install Details for NUC
=====================================
 * If Ubuntu says it cannot detect the CD-ROM:
   * `Alt-F2` to switch console
   * `Enter` to active the console
   * Type `umount /media`
   * `Alt-F1` to return to installer, and try to detect again
 * Set the hostname to `posm`
 * Set the local user name to `posm`
 * Set the time zone to `UTC` (press `End` key to get to the bottom of the list)
 * (Optional) Use LVM partitioning using only 20GB of space (so you can allocate remainder for data later)
 * No automatic updates (turn them on if the unit isn't going to the field)
