# posm-build

Interim Manual Build Process
============================

 1. Install Ubuntu 14.04 LTS minimal server however you like
 2.  `wget -q -O - https://github.com/AmericanRedCross/posm-build/archive/master.tar.gz | tar -zxf - -C /root --strip=2`
 3. `/root/scripts/bootstrap.sh -s "mysql_pw=posm" -s "mysql_size=small" gis osm mysql ruby postgis nodejs nginx fieldpapers`

Interim PXE Build Process
=========================

 1. Create a PXE boot server for Ubuntu 14.04 LTS
 2. Put `kickstart/POSM_Server.cfg` inplace on your PXE server wherever is appropriate
 3. Put this enitre repo at the root of your PXE web server
 4. PXE boot as approriate to use the `POSM_Server.cfg` preseed, for example, add the following on the kernel line: `auto=true url=http://ks/kickstart/POSM_Server.cfg`
