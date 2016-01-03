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

```
> make
```

This downloads `ubuntu-14.04.2-server-amd64.iso`, creates a custom
`ubuntu-14.04.2-server-amd64-unattended.iso` and run kvm to create
`ubuntu-14.04.2-server-amd64.img`.

## Run a brigde and some VMs

Run this command once:

```
> ./run-bridge.sh
```

This creates a bridge called `br0` used by VMs to talk to each other. A
`dnsmasq` container is run to serve IPs to those VMs.

Then (in different terminals):

```
> ./run-bridged-kvm.sh 1
> ./run-bridged-kvm.sh 2
> ./run-bridged-kvm.sh 3
> ./run-bridged-kvm.sh 4
> ./run-bridged-kvm.sh 5
```

The `run-bridged-kvm.sh` script will run a VM using the
`ubuntu-14.04.2-server-amd64.img` image in snapshot mode, i.e. changes will be
lost and the image left unaltered. In addition, simply rebooting will cause
`kvm` to exit. You can login using "horde" / "horde" directly or through SSH.

## Run a (lonely) VM

```
> ./run-kvm.sh 1
```

With something similar to the following in your `~/.ssh/config`

```
Host vm-1
  Hostname 127.0.0.1
  Port 22001
  User horde
```

it becomes easy to SSH into the VM:

```
> ssh vm-1
```
