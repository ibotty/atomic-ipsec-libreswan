#!/bin/bash
# Entrypoint for glusterfs-server

set -e

PLUTO_OPTIONS=""

if [ -f /etc/sysconfig/pluto ]; then
  . /etc/sysconfig/pluto
fi

PLUTO_OPTIONS="--config /etc/ipsec.conf --nofork --logfile /dev/stdout $PLUTO_OPTIONS"

USAGE="SYNOPSIS
       atomic run --spc -n ${NAME} ${IMAGE} COMMAND [arg...]

COMMANDS
       start
         Start ipsec_pluto(8) in foreground with config from /etc/ipsec.conf.

       stop
         Stop ipsec_pluto(8), and flush ipsec policy.

       reload
         Reload ipsec_pluto(8) configuration using ipsec_whack(8).

       <COMMAND> [arg...]
         Run ipsec(8) COMMAND with supplied arguments.

       bash | sh | /bin/bash | /bin/sh
         Run a shell in the container.

       usage
         Show this usage information.
"

err() {
  echo $* >&2
}

start() {
  /usr/libexec/ipsec/addconn --config /etc/ipsec.conf --checkconfig
  /usr/libexec/ipsec/_stackmanager start
  /sbin/ipsec --checknss

  exec /usr/libexec/ipsec/pluto $PLUTO_OPTIONS
}

reload() {
  /usr/libexec/ipsec/whack --listen
}

stop() {
  /usr/libexec/ipsec/whack --shutdown
  /sbin/ip xfrm policy flush
  /sbin/ip xfrm state flush
}

cmd="$1"
shift
case "$cmd" in
    start)
      start $@
      ;;
    reload)
      reload $@
      ;;
    stop)
      stop $@
      ;;
    bash|/bin/bash|sh|/bin/sh)
      exec /bin/bash "$@"
      ;;
    usage)
      echo "$USAGE"
      ;;
    *)
      exec /sbin/ipsec "$cmd" "$@"
      ;;
esac
