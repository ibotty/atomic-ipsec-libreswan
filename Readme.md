# IPSEC for (bare metal) atomic hosts

[![Docker
Status](https://dockeri.co/image/ibotty/ipsec-libreswan)](https://registry.hub.docker.com/u/ibotty/ipsec-libreswan/)

Atomic hosts do not support traditional installation of additional software
with e.g. rpm. That privileged docker container is meant to be run on system
startup (via a systemd unit) and support IPSEC for the docker host.

It uses Libreswan from the fedora 22 repository.


## Installation (broken, for now)

Run the following command to set up the necessary symlinks and systemd unit.
Unfortunately the Systemd unit will not start the container. See below on how
to fix that.

```shell
atomic run ibotty/ipsec-libreswan
```

If you don't run atomic but are certain you want to run Libreswan inside of a
container you can run the install script manually. This command is the same as
in the `LABEL INSTALL` in the Dockerfile.

```shell
docker run --rm --privileged --entrypoint /bin/sh -v /:/host \
  -e HOST=/host -e IMAGE=ipsec-libreswan -e NAME=ipsec-libreswan \
  ibotty/ipsec-libreswan /bin/install.sh
```

## Fix broken systemd unit

Fix up the `Exec*` lines in `/etc/systemd/system/ipsec.service`.


## Configuration

The configuration is on the host of `/etc/ipsec.conf`, `/etc/ipsec.secrets`
and `/etc/sysconfig/ipsec`. These files are symlinked from `/etc/ipsec` to
make the bind mount from host easier and more reliable.

Usually `/etc/ipsec.conf` and `/etc/ipsec.secrets` include files within
`/etc/ipsec.d`, which also gets mounted in the container.

See e.g. [the RHEL 7 Security
Guide](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Securing_Virtual_Private_Networks.html) on how to set up Libreswan.


