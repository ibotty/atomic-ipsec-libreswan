#!/bin/sh

set -e

if [ ! -d ${HOST}/etc/ipsec.d ] ; then
  mkdir ${HOST}/etc/ipsec.d
  chroot ${HOST} restorecon -R /etc/ipsec.d
fi

if [ ! -d ${HOST}/etc/ipsec ] ; then
  mkdir ${HOST}/etc/ipsec
fi

if [ ! -f ${HOST}/etc/ipsec/ipsec.conf ]; then
  cp /etc/ipsec/ipsec.conf $HOST/etc/ipsec/ipsec.conf
fi

if [ ! -f ${HOST}/etc/ipsec/ipsec.secrets ]; then
  cp /etc/ipsec/ipsec.secrets $HOST/etc/ipsec/ipsec.secrets
fi

if [ ! -f ${HOST}/etc/ipsec/sysconfig.ipsec ]; then
  cp /etc/ipsec/sysconfig.ipsec $HOST/etc/ipsec/sysconfig.ipsec
fi

if [ -f ${HOST}/etc/ipsec.conf ]; then
    mv ${HOST}/etc/ipsec.conf ${HOST}/etc/ipsec/ipsec.conf
fi

if [ -f ${HOST}/etc/ipsec.secrets ]; then
    mv ${HOST}/etc/ipsec.secrets ${HOST}/etc/ipsec/ipsec.secrets
fi

if [ -f ${HOST}/etc/sysconfig/ipsec ]; then
    mv ${HOST}/etc/sysconfig/ipsec ${HOST}/etc/ipsec/sysconfig.ipsec
fi

ln -fs /etc/ipsec/ipsec.conf ${HOST}/etc/ipsec.conf
ln -fs /etc/ipsec/ipsec.secrets ${HOST}/etc/ipsec.secrets
ln -fs /etc/ipsec/sysconfig.ipsec ${HOST}/etc/sysconfig/ipsec

DOCKER_CONTAINER_ID=$(/usr/bin/docker create ${IMAGE})

if [ -d /var/lib/machines/${NAME} ]; then
    rm -r /var/lib/machines/${NAME}
fi

mkdir -p /var/lib/machines/${NAME}

/usr/bin/docker export $DOCKER_CONTAINER_ID | tar -xC /var/lib/machines/${NAME}

cat <<EOF > ${HOST}/etc/systemd/system/ipsec.service

[Install]
WantedBy=multi-user.target

[Unit]
Description=LibreSwan IPSEC running in ${NAME}
After=docker.service
BindTo=docker.service

[Service]
ExecStart=/usr/bin/systemd-nspawn --quiet --capability CAP_NET_ADMIN --tmpfs /var/run/pluto --bind /proc/sys/net --bind-ro /lib/modules --bind /etc/ipsec --bind /etc/ipsec.d --machine=${NAME} /bin/entrypoint.sh start
ExecStop=/bin/sh -c '/usr/bin/systemd-run --machine ${NAME} /bin/entrypoint stop; /usr/bin/machinectl poweroff ${NAME}'
ExecReload=/usr/bin/systemd-run --machine ${NAME} /bin/entrypoint.sh reload

[Install]
WantedBy=multi-user.target
EOF
