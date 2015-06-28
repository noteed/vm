#! /bin/bash

# This script is run once on the host to allow VMs to talk to each other and to
# reach the internet.

# Should be done once, not per VM.
sudo brctl addbr br0
sudo ip a add 10.0.1.1 dev br0
sudo ip link set br0 up
sudo route add -net 10.0.1.0 netmask 255.255.255.0 dev br0

# Serve IP addresses on br0, should be done once too.
docker run -d \
  --name dnsmasq_for_kvm \
  -v $(pwd):/source --privileged --net host \
  images.reesd.com/reesd/dnsmasq /source/run-dnsmasq.sh

# Allow guests to reach internet.
sudo iptables -t nat -A POSTROUTING -s 10.0.1.1/24 ! -d 10.0.1.1/24 -j MASQUERADE
