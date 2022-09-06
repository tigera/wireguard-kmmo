#!/bin/bash

source "/etc/wireguard/wireguard-kmod.conf"

echo "Reloading kernel module"
echo "${0} ${1} ${2}"
/usr/bin/bash -c "/etc/kvc/wireguard-kmod-unload.sh" && \
/usr/bin/bash -c "/etc/kvc/wireguard-kmod-load.sh"