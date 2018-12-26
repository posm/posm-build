# POSM Build Scripts

These are the various build scripts that are used to provision POSM instances, devices, and
installers.

For installation and usage instructions, check out [posm.io](http://posm.io/docs)!

## Metal POSM

POSM runs on physical hardware! Intel NUCs work best (that's what we test on), but it's very likely
that it will work elsewhere.

The easiest way to get started is to [download the latest
release](https://github.com/posm/posm-build/releases) and copy it onto a USB
stick (at least 8GB).

[Etcher](https://etcher.io/) is the easiest way to create a USB installer.

Once you have created your installer USB stick, boot the target device from it. On the Intel NUC,
press `F10` on startup to get to the boot device menu. You will then be prompted to select
`Automated Installation`. This is what we want.

Wait for the installation to complete. We are copying several gigabytes worth of files, so it may
take 15 - 30 minutes. Once the installation is complete, your NUC will reboot to a login prompt. A
`POSM` wireless network should be available (assuming that the device contains a compatible wireless
card). The default WPA password is `awesomeposm` and it will start in "captive portal mode",
intercepting requests to HTTP web sites and redirecting users to the POSM landing page.

If you'd like to switch to "bridge mode" (where the POSM will act as a wireless router using its
ethernet port as an uplink), open "POSM Admin", choose "Network", and toggle the "captive / bridged"
setting. If "Network" is unavailable in the menu, you can navigate directly to
`http://posm.io/posm/settings`.

When connected to the `POSM` wireless network, you can `ssh` to the POSM using `ssh root@posm.io`.
`root`'s default password is `posm`. You should also be able to connect to it when connected to the
same network as the POSM's uplink, referring to it as `posm.local`.

### Hardware Requirements

* At least 2GB RAM, 8GB+ preferred
* At least a 16GB drive
* A compatible wireless adapter, for running a wireless network

## SuperPOSM

POSM has superhuman capabilities!

To add SuperPOSM capabilities (OpenDroneMap + GeoTIFF processing), add `docker redis imagery nodeodm
webodm` to the list of modules being deployed.

The minimal list of modules for SuperPOSM is: `base virt nginx admin docker redis imagery nodeodm
webodm`.

### SuperPOSM Hardware Requirements

* As much RAM as you can spare
* Fast storage
* Fast CPU(s), as many cores as you can spare

When building the OpenDroneMap integration, we tested using a [Skull Canyon
NUC](http://www.intel.com/content/www/us/en/nuc/nuc-kit-nuc6i7kyk-features-configurations.html) with
32GB RAM and a 256GB Samsung 950 Pro NVMe SSD.

## POSM AUX

POSMs can be clustered!

If you're using POSM for drone imagery processing, you can distribute
computation across multiple devices (just at the project level so far). To
enable this, image additional devices with `posm-aux.iso`. When all POSMs are
connected to the same wired network (and the primary POSM is started first),
each POSM AUX will register itself as a
[WebODM](https://www.opendronemap.org/webodm/) worker.

To provision POSM AUX from source, use these modules: `base odm-worker`.

When running POSM AUX on a network where mDNS doesn't work (i.e. a cloud
provider), WebODM processing nodes will need to be added manually. POSM AUX
uses port 3000 for workers.

## POSM Cloud

POSM runs in the cloud! To prepare a suitable instance, provision a virtual server running **Ubuntu
18.04** and ensure that you either have `root` or `sudo` access. 8GB of RAM is recommended, although
we've seen success with 4GB (and less may be necessary depending what you're doing). 10GB of disk
space should be sufficient, but more is welcome if you're going to incorporate SuperPOSM capabilities.

Before installation, you should choose a domain name and host to use to access your new POSM and
configure it with your DNS provider. If you don't do this, you won't be able to access the
OpenStreetMap interface.

Sample DNS records:

```text
my-posm.example.org     A     1.2.3.4
osm.my-posm.example.org CNAME posm.example.org
```

To configure POSM on your cloud host, connect to it using `ssh` and run the following commands.
`posm_hostname` should be set to the hostname component of the primary name (`my-posm`),
`posm_domain` to its TLD (`org`), and `posm_fqdn` to its full name (`my-posm.example.org`). If
you're using something other than `osm.<posm_fqdn>` for the OSM interface, you'll also need to
change `osm_fqdn`.

```bash
# become root
sudo -i

# install git if necessary
apt update && apt install --no-install-recommends -y git

# clone this repository
git clone https://github.com/AmericanRedCross/posm-build

# edit your settings (posm_hostname, posm_domain)
vi posm-build/kickstart/etc/settings

# bootstrap the necessary components (this will take a little while)
/root/posm-build/kickstart/scripts/bootstrap.sh base virt nodejs ruby gis \
  postgis nginx osm fieldpapers docker omk tl carto tessera admin
```

### Requirements

* **Ubuntu 18.04**
* At least 2GB RAM, 8GB+ preferred
* At least 10GB of attached storage
