#!/bin/sh
chroot ${HOST} /usr/bin/systemctl disable /etc/systemd/system/ipsec.service
rm -f ${HOST}/etc/systemd/system/ipsec.service
