# Live USB Installer

This folder contains scripts and resources to facilitate the creation of a Live USB installer.

It uses the [Ubuntu Live CD/USB
process](https://help.ubuntu.com/community/LiveCDCustomizationFromScratch)
([casper](http://manpages.ubuntu.com/manpages/wily/man7/casper.7.html)) with some modifications to
create an installer that runs under a GUI and copies a pre-installed set of packages + files to a
target system.

## Benefits over the previous installer

* No need for USB workarounds on fresh systems
  ([AmericanRedCross/posm#116](https://github.com/AmericanRedCross/posm/issues/116))
* Installs quickly
* Doesn't require an internet connection
* Distributed as an ISO (for Legacy BIOS support + VMs)
* Consistently installs a known set of dependencies / versions, simplifying validation
* Theoretically more CI-friendly (depends if LXD is installable in CI environments)
* Image can be created in a controlled environment with an HTTP cache / fast internet

## Downsides over the previous installer

* Less control over disk partitioning (creates single `/` partition)
* Larger initial download (full ISO)
* Not directly suited for cloud hosts (although it uses the same bootstrapping process)

## Why LXD?

If you read the
[LiveCDCustomizationFromScratch](https://help.ubuntu.com/community/LiveCDCustomizationFromScratch)
wiki, you'll see that `chroot`s are used extensively. `initctl` is diverted and
[`policy-rc.d`](https://people.debian.org/~hmh/invokerc.d-policyrc.d-specification.txt) is used to
prevent services from starting during installation. For producing a base system installer (i.e.
Ubuntu Desktop), this is desirable.

However, POSM needs to access a running PostgreSQL instance in order to initialize OSM (etc.). It's
possible to do this in a `chroot`, but with a high likelihood of port and device conflicts. Using
something that uses `cgroups` (e.g. Docker or LXC) makes it feasible.

[LXD](https://www.ubuntu.com/cloud/lxd) is an Ubuntu (etc.) wrapper around LXC that makes it behave
like a VM host, even allowing containers to run without privileges (so the full gamut of users
present in a container map to the user who invoked it). Guests are persistent, so commands can be
executed as though they were targeting a `chroot`ed environment while being able to access services
that were started (after removing the `initctl` diversion).

## ISO Creation

To create a Live Installer ISO, run:

```bash
make
```

This will produce `live-cd.iso`.

The git repo and branch used to bootstrap the installer can be provided as environment variables,
allowing for builds containing experimental features:

```bash
GIT_REPO=https://github.com/mojodna/posm-build GIT_BRANCH=integration make
```

To clean both the file artifacts and to remove the container used for installer creation
(appropriately named after adjectified animals, e.g. `noble gopher` or `promoted mastodon`), run:

```bash
make clean
```

LXD snapshots are created during each phase of the bootstrap process, allowing one to rollback to a
specific stage and re-run it if it failed. To do so, remove each of the marker files (e.g. `admin`,
`base`), delete newer snapshots (if using ZFS; `lxc delete $(cat container)/admin`), and restore the
parent of the stage you wish to re-run (`lxc info $(cat container)` provides a sequential list of
snapshots and therefore stages): `lxc restore $(cat container) <stage>`

This current snapshot recovery process is awkward, but may prove helpful under some circumstances.
In practice, I usually run `make clean` and start from scratch.

If you'd like to investigate the container after bootstrapping a specific phase, you can do this:

```bash
# start the container if it had been stopped, i.e. after postinstall
lxc start $(cat container)

# invoke a shell within the container
lxc exec $(cat container) bash
```
