#!/bin/bash

source "/etc/wireguard/wireguard-kmod.conf"

is_kmod_loaded() {
    module=${1//-/_} # replace any dashes with underscore
    if lsmod | grep "${module}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

echo "Loading kernel modules using the kernel module container..."
echo "${0} ${1} ${2}"
for module in ${KMOD_NAMES}; do
    echo "INFO: Loading kernel module: ${module}"
    if is_kmod_loaded ${module}; then
        echo "INFO: Kernel module ${module} already loaded"
    else
        module=${module//-/_} # replace any dashes with underscore
        modprobe ${module} && echo "SUCCESS: Kernel module ${module} loaded ok"
    fi
done
