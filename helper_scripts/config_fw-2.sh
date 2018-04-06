#!/bin/bash

echo "#################################"
echo "  Running Switch Post Config (config_fw-2.sh)"
echo "#################################"
sudo su

# Config for Hostname
cat <<EOT > /etc/hostname
fw-2
EOT

# Config for Hosts
cat <<EOT > /etc/hosts
127.0.0.1       fw-2       fw-2
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1  fw-2
EOT

hostname -F /etc/hostname

# Config for Vagrant Interface
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto mgmt
iface mgmt
    vrf-table auto

# The primary network interface
auto eth0
iface eth0
    address 192.168.100.32/24
    vrf mgmt

auto bond1
iface bond1
    bond-slaves swp0 swp1

# Switch virtual interface configuration SVI
auto bond1.901
iface bond1.901
    alias backend-transfer
    address 10.0.255.12/28

auto bond2
iface bond2
    bond-slaves swp2 swp3

# Switch virtual interface configuration SVI
auto bond2.903
iface bond2.903
    alias wan-transfer
    address 10.0.255.46/28

auto vagrant
iface vagrant
    vrf-table auto

auto eth1
iface eth1 inet dhcp
    alias Interface used by Vagrant
    vrf vagrant

source /etc/network/interfaces.d/*
EOT

cat <<EOT > /etc/frr/daemons
# This file tells the frr package which daemons to start.
#
# Entries are in the format: <daemon>=(yes|no|priority)
#   0, "no"  = disabled
#   1, "yes" = highest priority
#   2 .. 10  = lower priorities
# Read /usr/share/doc/frr/README.Debian for details.
#
# Sample configurations for these daemons can be found in
# /usr/share/doc/frr/examples/.
#
# ATTENTION:
#
# When activation a daemon at the first time, a config file, even if it is
# empty, has to be present *and* be owned by the user and group "frr", else
# the daemon will not be started by /etc/init.d/frr. The permissions should
# be u=rw,g=r,o=.
# When using "vtysh" such a config file is also needed. It should be owned by
# group "frrvty" and set to ug=rw,o= though. Check /etc/pam.d/frr, too.
#
# The watchfrr daemon is always started. Per default in monitoring-only but
# that can be changed via /etc/frr/daemons.conf.
#
zebra=yes
bgpd=no
ospfd=no
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
EOT

cat <<EOT > /etc/frr/frr.conf
frr version 3.2+cl3u1
frr defaults datacenter
hostname fw-2
username cumulus nopassword
!
service integrated-vtysh-config
!
log syslog informational
!
vrf Default-IP-Routing-Table
!
ip route 10.100.0.0/29 10.0.255.33
ip route 10.0.0.0/16 10.0.255.1
!
line vty
!
EOT

systemctl restart frr

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
echo "   Finished"
echo "#################################"
