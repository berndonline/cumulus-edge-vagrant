#!/bin/bash

echo "#################################"
echo "   Running config_mgmt_switch.sh"
echo "#################################"
sudo su

# Config for Hostname
cat <<EOT > /etc/hostname
mgmtsw01-d
EOT

# Config for Hosts
cat <<EOT > /etc/hosts
127.0.0.1       mgmtsw01-d       mgmtsw01-d
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1  mgmtsw01-d
EOT

hostname -F /etc/hostname

# Config for Mgmt Switch
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0

auto vagrant
iface vagrant
    vrf-table auto

auto eth1
iface eth1 inet dhcp
    alias Interface used by Vagrant
    vrf vagrant

auto bridge
iface bridge
    alias Untagged Bridge
    bridge-ports swp1 swp2 swp3 swp4 swp5 swp6
    hwaddress a0:00:00:00:00:61
    address 192.168.100.30/24
EOT

echo " ###Creating SSH keys for cumulus user ###"
mkdir -p /home/cumulus/.ssh

cat <<EOT > /home/cumulus/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzH+R+UhjVicUtI0daNUcedYhfvgT1dbZXgY33Ibm4MOo+X84Iwuzirm3QFnYf2O3uyZjNyrA6fj9qFE7Ekul4bD6PCstQupXPwfPMjns2M7tkHsKnLYjNxWNql/rCUxoH2B6nPyztcRCass3lIc2clfXkCY9Jtf7kgC2e/dmchywPV5PrFqtlHgZUnyoPyWBH7OjPLVxYwtCJn96sFkrjaG9QDOeoeiNvcGlk4DJp/g9L4f2AaEq69x8+gBTFUqAFsD8ecO941cM8sa1167rsRPx7SK3270Ji5EUF3lZsgpaiIgMhtIB/7QNTkN9ZjQBazxxlNVN6WthF8okb7OSt
EOT

cat /home/cumulus/.ssh/id_rsa.pub >> /home/cumulus/.ssh/authorized_keys

chmod 700 -R /home/cumulus/.ssh
chown cumulus:cumulus -R /home/cumulus/.ssh

echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus

echo "#################################"
echo "   Finished "
echo "#################################"
