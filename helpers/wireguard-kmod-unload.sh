#!/bin/bash

source "/etc/wireguard/wireguard-kmod.conf"

echo "Unloading kernel modules..."
echo "${0} ${1} ${2}"
for module in ${KMOD_NAMES}; do
    if is_kmod_loaded ${module}; then
        module=${module//-/_} # replace any dashes with underscore
        rmmod "${module}" && echo "SUCCESS: Kernel module ${module} unloaded ok"
    else
        echo "INFO: Kernel module ${module} already unloaded"
    fi
done