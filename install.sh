#!/bin/sh

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

ln -fs /etc/ipsec/ipsec.conf ${HOST}/etc/ipsec.conf
ln -fs /etc/ipsec/ipsec.secrets ${HOST}/etc/ipsec.secrets
ln -fs /etc/ipsec/sysconfig.ipsec ${HOST}/etc/sysconfig/ipsec

cat <<EOF > ${HOST}/etc/systemd/system/ipsec.service
[Unit]
Description=LibreSwan IPSEC running in ${NAME}
After=docker.service

[Service]
ExecStart=/usr/bin/docker run --rm --privileged --net=host -v /lib/modules:/lib/modules:ro -v /etc/ipsec:/etc/ipsec -v /etc/ipsec.d:/etc/ipsec.d --name ${NAME} ${IMAGE}
ExecStop=/bin/sh -c '/usr/bin/docker exec -t ${NAME} /bin/entrypoint.sh stop ; /usr/bin/docker stop ${NAME}'
ExecReload=/usr/bin/docker exec -t ${NAME} /bin/entrypoint.sh reload

[Install]
WantedBy=multi-user.target
EOF
