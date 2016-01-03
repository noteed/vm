#! /bin/bash

# Should be 1, 2, 3, 4 or 5
VM_ID=$1

TAP="tap${VM_ID}"
MAC="DE:AD:BE:EF:9E:2${VM_ID}"

kvm \
  -nographic -snapshot -no-reboot \
  -m 256 \
  -device e1000,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2200${VM_ID}-:22 \
  -boot d ubuntu-14.04.2-server-amd64.img

#  -device e1000,netdev=net0,mac=${MAC} \
#  -netdev tap,id=net0,ifname=${TAP},script=no \
