FROM fedora:22
MAINTAINER Tobias Florek tob@butter.sh

EXPOSE 500 4500 50 51

LABEL INSTALL="docker run --rm --privileged --entrypoint /bin/sh -v /:/host -e HOST=/host -e LOGDIR=\${LOGDIR} -e CONFDIR=\${CONFDIR} -e DATADIR=\${DATADIR} -e IMAGE=IMAGE -e NAME=NAME IMAGE /bin/install.sh"

LABEL UNINSTALL="docker run --rm --privileged --entrypoint /bin/sh -v /:/host -e HOST=/host -e IMAGE=IMAGE -e NAME=NAME IMAGE /bin/uninstall.sh"

LABEL RUN="docker run -d --privileged --net=host -v /lib/modules:/lib/modules:ro -v /etc/ipsec:/etc/ipsec -v /etc/ipsec.d:/etc/ipsec.d -n NAME start"

VOLUME ["/lib/modules", "/etc/ipsec", "/etc/ipsec.d"]

RUN dnf --setopt=tsflags=nodocs -y install libreswan \
 && dnf clean all \
 && cp /etc/ipsec.conf /root/ipsec.conf \
 && cp /etc/ipsec.secrets /root/ipsec.secrets \
 && cp /etc/sysconfig/ipsec /root/sysconfig.ipsec \
 && ln -fs /etc/ipsec/ipsec.conf /etc/ipsec.conf \
 && ln -fs /etc/ipsec/ipsec.secrets /etc/ipsec.secrets \
 && ln -fs /etc/ipsec/sysconfig.ipsec /etc/sysconfig/ipsec

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["start"]

ADD install.sh uninstall.sh entrypoint.sh /bin/
