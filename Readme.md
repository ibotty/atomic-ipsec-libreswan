# IPSEC for (bare metal) atomic hosts

[![Docker
Status](https://dockeri.co/image/ibotty/ipsec-libreswan)](https://registry.hub.docker.com/u/ibotty/ipsec-libreswan/)

Atomic hosts do not support traditional installation of additional software
with e.g. rpm. That privileged docker container is meant to be run on system
startup (via a systemd unit) and support IPSEC for the docker host.

It uses Libreswan from the fedora 22 repository.


## Installation

### Automatically starting via Systemd Unit
Run the following command to set up the necessary symlinks and systemd unit.

```shell
atomic install ibotty/ipsec-libreswan
```

You might want to start and enable it afterwards.

```shell
systemctl daemon-reload
systemctl enable ipsec.service
systemctl restart ipsec.service
```

If you don't run atomic but are certain you want to run Libreswan inside of a
container you can run the install script manually. This command is the same as
in the `LABEL INSTALL` in the Dockerfile.

```shell
docker run --rm --privileged --entrypoint /bin/sh -v /:/host \
  -e HOST=/host -e IMAGE=ipsec-libreswan -e NAME=ipsec-libreswan \
  ibotty/ipsec-libreswan /bin/install.sh
```

### By hand

Start ipsec IKE daemon (pluto) by running the following command.

```shell
docker run --rm --privileged --net=host \
       -v /lib/modules:/lib/modules:ro -v /etc/ipsec:/etc/ipsec \
       -v /etc/ipsec.d:/etc/ipsec.d --name ipsec-libreswan \
       ibotty/libreswan
```

or use systemd:

```shell
systemd-nspawn --quiet --capability all --tmpfs /var/run/pluto \
               --bind /proc/sys/net --bind-ro /lib/modules --bind /etc/ipsec \
               --bind /etc/ipsec.d --machine=ipsec-libreswan /bin/entrypoint.sh start
```

## Configuration

### Config files

The configuration is on the host of `/etc/ipsec.conf`, `/etc/ipsec.secrets`
and `/etc/sysconfig/ipsec`. These files are symlinked from `/etc/ipsec` to
make the bind mount from host easier and more reliable.

Usually `/etc/ipsec.conf` and `/etc/ipsec.secrets` include files within
`/etc/ipsec.d`, which also gets mounted in the container.

See e.g. [the RHEL 7 Security
Guide](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Securing_Virtual_Private_Networks.html) on how to set up Libreswan.

### ipsec tool
When configuring using the ipsec tool, call

```shell
/usr/bin/docker exec -t ipsec-libreswan /bin/entrypoint.sh
```

as you would call ipsec. Be sure to create the config files in /etc/ipsec.d as
mentioned above.

