#! /bin/bash

# This script is run automatically as `late_command`.
# It is used to install a few things such as Docker or OpenSSH.

apt-get update
apt-get install -q -y openssh-server

# Allow to ssh into the VM.
mkdir /home/horde/.ssh
cat <<END > /home/horde/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcGFyjPy2kQ8RdrHa7TMTn6meduYJxu01V/Cs8vln5Dqs5weEBS0HkhLdg/Txedev+hsNS0QxsR0NufqJEDBSL1OMQ+g0VXPfGSR3XzA+zHAhO/zn48xQ1MrTZ+RTIjBSxtp8hXADki+/oJEhuD2pIH8hjK/ATfRYkeCv4QsDl8B+3rQTbk6Xn86rNpphoQSo1MLrRK1idZ2l0Yfa3JkCofxWEN39JB9XZIeoP6IuM7NgJVxopy1FiUXmHbPUDMEMCmsSLCCs7u/5q0WANE3hc9P/zyPPm2sd1KtxvEnbHAcK1uh2zDVlrslXFpVZtcct8KBZ3EgBtlB9t+7FGR7/p
END
chown -R horde:horde /home/horde/.ssh
mod 0600 /home/horde/.ssh/authorized_keys

# Install Docker.
DEBIAN_FRONTEND=noninteractive apt-get install -q -y apt-transport-https
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -q -y lxc-docker-1.3.3

# Install `brctl` command.
apt-get install -q -y bridge-utils

# Install Tinc. The /etc/tinc directory was copied by late_command.
apt-get install -q -y tinc
