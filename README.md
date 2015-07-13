# VM

This repository contains:

- a script to build a Ubuntu ISO file for unattended install,
- a script to build a KVM image using the above ISO,
- a script to run a bridge to allow VMs to talk to each others,
- a script to run VMs using that bridge.

The first script is based on: https://github.com/netson/ubuntu-unattended.

The resulting image is already provisioned with Docker and Tinc. It also
contains a script to configure Docker and Tinc in such a way that containers
running on multiple VMs can talk to each others. That script is run
automatically when the VM boots (it's called from `rc.local`).

## Build the VM iso and image

    make

## Run a brigde and some VMs

Once:

    ./run-bridge.sh

Then (in different terminals):

    ./run-kvm.sh 1
    ./run-kvm.sh 2
    ./run-kvm.sh 3
    ./run-kvm.sh 4
    ./run-kvm.sh 5

The `run-kvm.sh` script will run a VM in snapshot mode, i.e. changes will be
lost and the image left unaltered. In addition, simply rebooting will cause
`kvm` to exit. You can login using "horde" / "horde" directly or through SSH.
