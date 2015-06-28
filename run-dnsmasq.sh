#! /bin/bash

# This is a helper script used by `run-bridge.sh`.

cat <<END > /etc/dnsmasq.conf
listen-address=10.0.1.1
bind-interfaces
dhcp-range=10.0.1.50,10.0.1.150,255.0.0.0,12h
dhcp-host=DE:AD:BE:EF:9E:21,10.0.1.21
dhcp-host=DE:AD:BE:EF:9E:22,10.0.1.22
dhcp-host=DE:AD:BE:EF:9E:23,10.0.1.23
dhcp-host=DE:AD:BE:EF:9E:24,10.0.1.24
dhcp-host=DE:AD:BE:EF:9E:25,10.0.1.25
END

sed -i -e '/__LOCAL_IP__/d' /etc/dnsmasq.conf

dnsmasq -d -C /etc/dnsmasq.conf
