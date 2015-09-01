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

mkdir -p ${HOST}/var/lib/machines/${NAME}

cat <<EOF > ${HOST}/etc/systemd/system/ipsec.service
[Unit]
Description=LibreSwan IPSEC running in ${NAME}
After=network-online.target

[Service]
ExecStartPre=/bin/atomic mount -o rw ${IMAGE} /var/lib/machines/${NAME}
ExecStart=/bin/systemd-nspawn --quiet --capability all --tmpfs /var/run/pluto --bind /proc/sys/net --bind-ro /lib/modules --bind /etc/ipsec --bind /etc/ipsec.d --machine=${NAME} /bin/entrypoint.sh start
ExecStop=/bin/sh -c '/bin/systemd-run --machine ${NAME} /bin/entrypoint stop; /bin/machinectl poweroff ${NAME}'
ExecReload=/bin/systemd-run --machine ${NAME} /bin/entrypoint.sh reload

[Install]
WantedBy=multi-user.target
EOF

