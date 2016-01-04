#! /bin/bash

# Should be 1, 2, 3, 4 or 5
VM_ID=$1

TAP="tap${VM_ID}"
MAC="DE:AD:BE:EF:9E:2${VM_ID}"

sudo tunctl -u `whoami` -t ${TAP}
sudo ip link set ${TAP} up
sleep 0.5s
sudo brctl addif br0 ${TAP}

sleep 1

kvm \
  -nographic -snapshot -no-reboot \
  -m 256 \
  -device e1000,netdev=net0,mac=${MAC} \
  -netdev tap,id=net0,ifname=${TAP},script=no \
  -boot d ubuntu-14.04.3-server-amd64.img


sudo brctl delif br0 ${TAP}
sudo tunctl -d ${TAP}
