#!/usr/bin/bash
set -x
main() {
    ignition_file='/home/core/config.ign'

    if [ -b /dev/sda ]; then
        install_device='/dev/sda'
    elif [ -b /dev/nvme0 ]; then
        install_device='/dev/nvme0'
    else
        echo "Can't find appropriate device to install to" 1>&2
        poststatus 'failure'
        return 1
    fi

    cmd="coreos-installer install --console tty0"
    cmd+=" --ignition-file=${ignition_file}"
    cmd+=" ${install_device}"

    if $cmd; then
        echo "Install Succeeded!"
        return 0
    else
        echo "Install Failed!"
        return 1
    fi
}
main
