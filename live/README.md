# Live USB Installer

This folder contains scripts and resources to facilitate the creation of a
Live USB installer.

There are 3 variants:

* `posm` - the POSM you know and love
* `superposm` - POSM with drone imagery processing capabilities
* `posm-aux` - auxiliary services to allow
  [WebODM](https://www.opendronemap.org/webodm/) to use multiple devices

The installer uses the same mechanism as [MaaS](https://maas.io/) to install
a pre-built root filesystem on a bare system:
[subiquity](https://github.com/CanonicalLtd/subiquity), Ubuntu's new server
installer. Under the hood, subiquity uses
[curtin](https://launchpad.net/curtin) to configure and image the hardware.

This means that there are 2 components to creating an installer:

* initialization of a root filesystem with desired components
* creation of an installer ISO with subiquity confgured to install the POSM
  root filesystem

[LXD](https://linuxcontainers.org/lxd/) containers are driven by the
`Makefile` to run the various bootstrap scripts.

[POSM's subiquity fork](https://github.com/posm/subiquity) contains changes
that strip out unnecessary user interaction during installation.

## Why LXD

POSM needs to access a running PostgreSQL instance in order to initialize OSM
(etc.). It's possible to do this in a `chroot`, but with a high likelihood of
port and device conflicts. Using something that uses `cgroups` (e.g. Docker
or LXC) makes it feasible.

[LXD](https://www.ubuntu.com/cloud/lxd) is an Ubuntu (etc.) wrapper around
LXC that makes it behave like a VM host, even allowing containers to run
without privileges (so the full gamut of users present in a container map to
the user who invoked it). Guests are persistent, so commands can be executed
as though they were targeting a `chroot`ed environment while being able to
access services that were started.

## ISO Creation

We've tested using Amazon EC2 t2.xlarge (for 16GB RAM) running Ubuntu Server 18.04 with 60GB disk storage.
To setup and install dependencies, run:
```bash
git clone https://github.com/posm/posm-build.git
cd posm-build
git submodule update --init 
cd subiquity && make install_deps
cd ../
sudo apt install make lxd pigz snapcraft p7zip-full xorriso isolinux
lxd init  # accepting all defaults
```

To create a Live Installer ISO, run:

```bash
make
```

This will produce `posm.iso`. If you'd like the SuperPOSM or `aux` variants,
use `make superposm.iso` or `make posm-aux.iso`.

After running `make` (either failure or success) and before running `make` again you will want to run `make clean`. So a sample workflow might be:
1. `make`
2. Copy out the posm.iso file
3. `make clean superposm.iso`
4. Copy out the superposm.iso file

The git repo and branch used to bootstrap the installer can be provided as
environment variables, allowing for builds containing experimental features:

```bash
GIT_REPO=https://github.com/mojodna/posm-build GIT_BRANCH=integration make
```

To clean both the file artifacts and to remove the container used for
installer creation (appropriately named after adjectified animals, e.g.
`noble gopher` or `promoted mastodon`), run:

```bash
make clean
```

LXD snapshots are created during each phase of the bootstrap process,
allowing one to rollback to a specific stage and re-run it if it failed. To
do so, remove each of the marker files (e.g. `admin`, `base`), delete newer
snapshots (if using ZFS; `lxc delete $(cat container)/admin`), and restore
the parent of the stage you wish to re-run (`lxc info $(cat container)`
provides a sequential list of snapshots and therefore stages): `lxc restore
$(cat container) <stage>`

This current snapshot recovery process is awkward, but may prove helpful
under some circumstances. In practice, I usually run `make clean` and start
from scratch.

If you'd like to investigate the container after bootstrapping a specific
phase, you can do this:

```bash
# start the container if it had been stopped
lxc start $(< container)

# invoke a shell within the container
lxc exec $(< container) bash
```
