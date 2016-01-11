#!/bin/sh
set -e

SYSTEMD_VERSION=$(chroot $HOST rpm -q systemd --queryformat '%{VERSION}')

if [ ! -d ${HOST}/etc/ipsec.d ] ; then
  mkdir ${HOST}/etc/ipsec.d
  chroot ${HOST} restorecon -R /etc/ipsec.d
fi

if [ ! -d ${HOST}/etc/ipsec ] ; then
  mkdir ${HOST}/etc/ipsec
fi

if [ ! -f ${HOST}/etc/ipsec/ipsec.conf ]; then
  cp /root/ipsec.conf $HOST/etc/ipsec/ipsec.conf
fi

if [ ! -f ${HOST}/etc/ipsec/ipsec.secrets ]; then
  cp /root/ipsec.secrets $HOST/etc/ipsec/ipsec.secrets
fi

if [ ! -f ${HOST}/etc/ipsec/sysconfig.ipsec ]; then
  cp /root/sysconfig.ipsec $HOST/etc/ipsec/sysconfig.ipsec
fi

if [ -f ${HOST}/etc/ipsec.conf ]; then
    mv -f ${HOST}/etc/ipsec.conf ${HOST}/etc/ipsec/ipsec.conf
fi

if [ -f ${HOST}/etc/ipsec.secrets ]; then
    mv -f ${HOST}/etc/ipsec.secrets ${HOST}/etc/ipsec/ipsec.secrets
fi

if [ -f ${HOST}/etc/sysconfig/ipsec ]; then
    mv -f ${HOST}/etc/sysconfig/ipsec ${HOST}/etc/ipsec/sysconfig.ipsec
fi

ln -fs /etc/ipsec/ipsec.conf ${HOST}/etc/ipsec.conf
ln -fs /etc/ipsec/ipsec.secrets ${HOST}/etc/ipsec.secrets
ln -fs /etc/ipsec/sysconfig.ipsec ${HOST}/etc/sysconfig/ipsec

DOCKER_CONTAINER_ID=$(chroot $HOST /usr/bin/docker create ${IMAGE})

chroot $HOST /usr/bin/systemctl stop ipsec || true

if [ -d ${HOST}/var/lib/machines/${NAME} ]; then
    rm -r ${HOST}/var/lib/machines/${NAME}
fi

mkdir -p ${HOST}/var/lib/machines/${NAME}

chroot $HOST /usr/bin/docker export $DOCKER_CONTAINER_ID \
  | chroot $HOST /usr/bin/tar -xC /var/lib/machines/${NAME}

chroot $HOST /usr/bin/docker rm $DOCKER_CONTAINER_ID

if [ $SYSTEMD_VERSION -ge 219 ]; then
    cat <<EOF > ${HOST}/etc/systemd/system/ipsec.service
[Unit]
Description=LibreSwan IPSEC running in ${NAME}
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/bin/systemd-nspawn --quiet --capability CAP_NET_ADMIN,CAP_SYS_MODULE --tmpfs /var/run/pluto --bind /proc/sys/net --bind-ro /lib/modules --bind /etc/ipsec --bind /etc/ipsec.d --machine=${NAME} -jb
ExecStop=/bin/machinectl poweroff ${NAME}
ExecReload=/bin/systemctl --machine ${NAME} reload ipsec

[Install
WantedBy=multi-user.target
EOF

else
    cat <<EOF > ${HOST}/etc/systemd/system/ipsec.service
[Unit]
Description=LibreSwan IPSEC running in ipsec-libreswan
After=network-online.target
Wants=network-online.target

[Service]
ExecStartPre=systemd-machine-id-setup --root /var/lib/machines/ipsec-libreswan
ExecStart=/bin/systemd-nspawn --capability CAP_NET_ADMIN,CAP_SYS_MODULE --bind /proc/sys/net --bind-ro /lib/modules --bind /etc/ipsec --bind /etc/ipsec.d --machine=ipsec-libreswan -jb -D /var/lib/machines/ipsec-libreswan

[Install]
WantedBy=multi-user.target
EOF

fi
