# posm-build

Interim Manual Build Process
============================

 1. Install Ubuntu 14.04 LTS minimal server however you like
 2.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
 3. Put any local settings in `/root/etc/settings.local` (see `/root/etc/settings`)
 4. `/root/scripts/bootstrap.sh base nodejs ruby gis osm mysql postgis nginx fieldpapers omk mbtiles tessera`
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
| `/tl` | [tessera](https://github.com/mojodna/tessera) | http://127.0.0.1:8082 |
| `/fp-tiler` | [Field Papers Tiler](https://github.com/fieldpapers/fp-tiler) | http://127.0.0.1:8080/fp-tiler |
| `/fp-tasks` | [Field Papers Tasks](https://github.com/fieldpapers/fp-tasks) | http://127.0.0.1:8081/fp-tasks |
| `/omk` | [OpenMapKit Server](https://github.com/AmericanRedCross/OpenMapKitServer) | http://127.0.0.1:3210 |
