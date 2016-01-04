#! /bin/bash

DEVICE=$(sudo blkid -L CONFIGDISK)

if [ -n "${DEVICE}" ] ; then
  sudo mkdir -p /media/config
  sudo mount ${DEVICE} /media/config
  if [ -f /media/config/setup.sh ] ; then
    cd /media/config/
    sh setup.sh
  fi
  exit 0
fi

# TODO The rest of the script should be provided by the config disk.

# Bridge the Docker subnet to the Tinc VPN.
# This can be run at VM startup time.

# From http://goldmann.pl/blog/2014/01/21/connecting-docker-containers-on-multiple-hosts/,
# modified to use Tinc instead of Open vSwitch.

LAST_NR=$(ip a s eth0 | grep 'inet ' | sed -e 's@ *inet 10.0.1.\([^/]*\)/.*@\1@')
LAST_DIGIT=$(echo ${LAST_NR} | sed 's/2\(.\)/\1/')

# The bridge address on 'this' VM.
BRIDGE_ADDRESS="172.18.${LAST_NR}.1/24"
BRIDGE_ADDRESS_="172.18.${LAST_NR}.1"

# The bridge address on the 'other' host.
declare -a ALL_BRIDGE_ADDRESSES=("172.18.21.0" "172.18.22.0" "172.18.23.0" "172.18.24.0" "172.18.25.0")
declare -a OTHER_BRIDGE_ADDRESSES=(${ALL_BRIDGE_ADDRESSES[@]//172.18.${LAST_NR}.0})

# Name of the bridge (should match /etc/default/docker and /etc/tinc/).
BRIDGE_NAME=docker0

# bridges

# Deactivate the docker0 bridge
ip link set $BRIDGE_NAME down
# Remove the docker0 bridge
brctl delbr $BRIDGE_NAME
# Add the docker0 bridge
brctl addbr $BRIDGE_NAME
# Set up the IP for the docker0 bridge
ip a add $BRIDGE_ADDRESS dev $BRIDGE_NAME
# Activate the bridge
ip link set $BRIDGE_NAME up

# Start Tinc, this creates `horde`, similar to `br0` in the Open vSwitch script.
sed -i -e "s/__name__/vm_${LAST_DIGIT}/" /etc/tinc/horde/tinc.conf
sed -i -e "s/__address__/172.18.${LAST_NR}.0/" /etc/tinc/horde/tinc.conf
sed -i -e "s/__connect__/vm_$((${LAST_DIGIT} % 5 + 1))/" /etc/tinc/horde/tinc.conf
mv /etc/tinc/horde/vm_${LAST_DIGIT}_rsa_key.priv /etc/tinc/horde/rsa_key.priv
service tinc restart

# Restart Docker daemon to use the new BRIDGE_NAME
service docker restart

# Make the 'other' subnets routable.
for OTHER_BRIDGE_ADDRESS in "${OTHER_BRIDGE_ADDRESSES[@]}"
do
  route add -net $OTHER_BRIDGE_ADDRESS netmask 255.255.255.0 dev $BRIDGE_NAME
done

# Allow containers on the VM reach the internet.
iptables -t nat -A POSTROUTING \
  -s 172.18.${LAST_NR}.1/24 ! -d 172.18.${LAST_NR}.1/24 \
  -j MASQUERADE
