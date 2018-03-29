# Created by Topology-Converter v4.6.3
#    Template Revision: v4.6.3
#    https://github.com/cumulusnetworks/topology_converter
#    using topology data from: ./topology.dot
#    built with the following args: ./topology_converter.py ./topology.dot -p libvirt --ansible-hostfile
#
#    NOTE: in order to use this Vagrantfile you will need:
#       -Vagrant(v1.8.6+) installed: http://www.vagrantup.com/downloads
#       -the "helper_scripts" directory that comes packaged with topology-converter.py
#        -Libvirt Installed -- guide to come
#       -Vagrant-Libvirt Plugin installed: $ vagrant plugin install vagrant-libvirt
#       -Boxes which have been mutated to support Libvirt -- see guide below:
#            https://community.cumulusnetworks.com/cumulus/topics/converting-cumulus-vx-virtualbox-vagrant-box-gt-libvirt-vagrant-box
#       -Start with \"vagrant up --provider=libvirt --no-parallel\n")

#Set the default provider to libvirt in the case they forget --provider=libvirt or if someone destroys a machine it reverts to virtualbox
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'libvirt'

Vagrant.require_version ">= 1.8.6", "< 2.0.0"

# Check required plugins
REQUIRED_PLUGINS_LIBVIRT = %w(vagrant-libvirt)
exit unless REQUIRED_PLUGINS_LIBVIRT.all? do |plugin|
  Vagrant.has_plugin?(plugin) || (
    puts "The #{plugin} plugin is required. Please install it with:"
    puts "$ vagrant plugin install #{plugin}"
    false
  )
end


$script = <<-SCRIPT
if grep -q -i 'cumulus' /etc/lsb-release &> /dev/null; then
    echo "### RUNNING CUMULUS EXTRA CONFIG ###"
    source /etc/lsb-release
    if [[ $DISTRIB_RELEASE =~ ^2.* ]]; then
        echo "  INFO: Detected a 2.5.x Based Release"

        echo "  adding fake cl-acltool..."
        echo -e "#!/bin/bash\nexit 0" > /usr/bin/cl-acltool
        chmod 755 /usr/bin/cl-acltool

        echo "  adding fake cl-license..."
        echo -e "#!/bin/bash\nexit 0" > /usr/bin/cl-license
        chmod 755 /usr/bin/cl-license

        echo "  Disabling default remap on Cumulus VX..."
        mv -v /etc/init.d/rename_eth_swp /etc/init.d/rename_eth_swp.backup

        echo "### Rebooting to Apply Remap..."

    elif [[ $DISTRIB_RELEASE =~ ^3.* ]]; then
        echo "  INFO: Detected a 3.x Based Release"
        echo "### Disabling default remap on Cumulus VX..."
        mv -v /etc/hw_init.d/S10rename_eth_swp.sh /etc/S10rename_eth_swp.sh.backup &> /dev/null
        echo "### Disabling ZTP service..."
        systemctl stop ztp.service
        ztp -d 2>&1
        echo "### Resetting ZTP to work next boot..."
        ztp -R 2>&1
        echo "  INFO: Detected Cumulus Linux v$DISTRIB_RELEASE Release"
        if [[ $DISTRIB_RELEASE =~ ^3.[1-9].* ]]; then
            echo "### Fixing ONIE DHCP to avoid Vagrant Interface ###"
            echo "     Note: Installing from ONIE will undo these changes." 
            mkdir /tmp/foo
            mount LABEL=ONIE-BOOT /tmp/foo
            sed -i 's/eth0/eth1/g' /tmp/foo/grub/grub.cfg
            sed -i 's/eth0/eth1/g' /tmp/foo/onie/grub/grub-extra.cfg
            umount /tmp/foo
        fi
        if [[ $DISTRIB_RELEASE =~ ^3.[2-9].* ]]; then
            if [[ $(grep "vagrant" /etc/netd.conf | wc -l ) == 0 ]]; then
                echo "### Giving Vagrant User Ability to Run NCLU Commands ###"
                sed -i 's/users_with_edit = root, cumulus/users_with_edit = root, cumulus, vagrant/g' /etc/netd.conf
                sed -i 's/users_with_show = root, cumulus/users_with_show = root, cumulus, vagrant/g' /etc/netd.conf
            fi
        fi

    fi
fi
echo "### DONE ###"
echo "### Rebooting Device to Apply Remap..."
nohup bash -c 'sleep 10; shutdown now -r "Rebooting to Remap Interfaces"' &
SCRIPT

Vagrant.configure("2") do |config|

  config.vm.provider :libvirt do |domain|
    # increase nic adapter count to be greater than 8 for all VMs.
    domain.management_network_address = "10.255.1.0/24"
    domain.management_network_name = "wbr1"
    domain.nic_adapter_count = 130
  end


  #Generating Ansible Host File at following location:
  #    ./.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./helper_scripts/empty_playbook.yml"
# ANSIBLE GROUPS CONFIGURATION
    ansible.groups = {
      "edge" => ["edge-2","edge-1","wan-1","wan-2",],
      "exit" => ["fw-2","fw-1",],
      "mgmt" => ["mgmt-1",],
      "network:children" => ["edge",]
    }
  end


  ##### DEFINE VM for fw-2 #####
  config.vm.define "fw-2" do |device|
    device.vm.hostname = "fw-2" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp6
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1f",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8016',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9016',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp0 --> edge-1:swp48
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0b",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8006',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9006',
            :libvirt__iface_name => 'swp0',
            auto_config: false
      # link for swp1 --> edge-2:swp48
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:05",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8003',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9003',
            :libvirt__iface_name => 'swp1',
            auto_config: false
      # link for swp2 --> wan-1:swp48
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:2b",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8022',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9022',
            :libvirt__iface_name => 'swp2',
            auto_config: false
      # link for swp3 --> wan-2:swp48
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0d",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8007',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9007',
            :libvirt__iface_name => 'swp3',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_fw-2.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1f --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1f", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0b --> swp0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0b", NAME="swp0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:05 --> swp1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:05", NAME="swp1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:2b --> swp2"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:2b", NAME="swp2", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0d --> swp3"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0d", NAME="swp3", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for fw-1 #####
  config.vm.define "fw-1" do |device|
    device.vm.hostname = "fw-1" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp5
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:17",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8012',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9012',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp0 --> edge-1:swp47
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:01",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8001',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9001',
            :libvirt__iface_name => 'swp0',
            auto_config: false
      # link for swp1 --> edge-2:swp47
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:13",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8010',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9010',
            :libvirt__iface_name => 'swp1',
            auto_config: false
      # link for swp2 --> wan-1:swp47
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1d",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8015',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9015',
            :libvirt__iface_name => 'swp2',
            auto_config: false
      # link for swp3 --> wan-2:swp47
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:07",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8004',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9004',
            :libvirt__iface_name => 'swp3',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_fw-1.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:17 --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:17", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:01 --> swp0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:01", NAME="swp0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:13 --> swp1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:13", NAME="swp1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1d --> swp2"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1d", NAME="swp2", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:07 --> swp3"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:07", NAME="swp3", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for mgmt-1 #####
  config.vm.define "mgmt-1" do |device|
    device.vm.hostname = "mgmt-1" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for swp1 --> edge-1:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:10",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9008',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8008',
            :libvirt__iface_name => 'swp1',
            auto_config: false
      # link for swp2 --> edge-2:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:12",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9009',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8009',
            :libvirt__iface_name => 'swp2',
            auto_config: false
      # link for swp3 --> wan-1:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1a",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9013',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8013',
            :libvirt__iface_name => 'swp3',
            auto_config: false
      # link for swp4 --> wan-2:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:24",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9018',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8018',
            :libvirt__iface_name => 'swp4',
            auto_config: false
      # link for swp5 --> fw-1:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:18",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9012',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8012',
            :libvirt__iface_name => 'swp5',
            auto_config: false
      # link for swp6 --> fw-2:eth0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:20",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9016',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8016',
            :libvirt__iface_name => 'swp6',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_mgmt_switch.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:10 --> swp1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:10", NAME="swp1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:12 --> swp2"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:12", NAME="swp2", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1a --> swp3"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1a", NAME="swp3", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:24 --> swp4"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:24", NAME="swp4", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:18 --> swp5"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:18", NAME="swp5", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:20 --> swp6"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:20", NAME="swp6", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for edge-2 #####
  config.vm.define "edge-2" do |device|
    device.vm.hostname = "edge-2" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp2
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:11",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8009',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9009',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp47 --> fw-1:swp1
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:14",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9010',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8010',
            :libvirt__iface_name => 'swp47',
            auto_config: false
      # link for swp48 --> fw-2:swp1
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:06",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9003',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8003',
            :libvirt__iface_name => 'swp48',
            auto_config: false
      # link for swp53 --> edge-1:swp53
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0a",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9005',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8005',
            :libvirt__iface_name => 'swp53',
            auto_config: false
      # link for swp54 --> edge-1:swp54
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:28",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9020',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8020',
            :libvirt__iface_name => 'swp54',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:11 --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:11", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:14 --> swp47"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:14", NAME="swp47", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:06 --> swp48"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:06", NAME="swp48", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0a --> swp53"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0a", NAME="swp53", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:28 --> swp54"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:28", NAME="swp54", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for edge-1 #####
  config.vm.define "edge-1" do |device|
    device.vm.hostname = "edge-1" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp1
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0f",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8008',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9008',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp47 --> fw-1:swp0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:02",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9001',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8001',
            :libvirt__iface_name => 'swp47',
            auto_config: false
      # link for swp48 --> fw-2:swp0
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0c",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9006',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8006',
            :libvirt__iface_name => 'swp48',
            auto_config: false
      # link for swp53 --> edge-2:swp53
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:09",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8005',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9005',
            :libvirt__iface_name => 'swp53',
            auto_config: false
      # link for swp54 --> edge-2:swp54
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:27",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8020',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9020',
            :libvirt__iface_name => 'swp54',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0f --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0f", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:02 --> swp47"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:02", NAME="swp47", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0c --> swp48"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0c", NAME="swp48", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:09 --> swp53"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:09", NAME="swp53", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:27 --> swp54"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:27", NAME="swp54", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for wan-1 #####
  config.vm.define "wan-1" do |device|
    device.vm.hostname = "wan-1" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp3
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:19",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8013',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9013',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp1 --> provider:swp1
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:26",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9019',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8019',
            :libvirt__iface_name => 'swp1',
            auto_config: false
      # link for swp2 --> provider:swp3
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:2a",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9021',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8021',
            :libvirt__iface_name => 'swp2',
            auto_config: false
      # link for swp47 --> fw-1:swp2
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1e",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9015',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8015',
            :libvirt__iface_name => 'swp47',
            auto_config: false
      # link for swp48 --> fw-2:swp2
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:2c",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9022',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8022',
            :libvirt__iface_name => 'swp48',
            auto_config: false
      # link for swp51 --> wan-2:swp51
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:03",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8002',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9002',
            :libvirt__iface_name => 'swp51',
            auto_config: false
      # link for swp52 --> wan-2:swp52
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1b",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8014',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9014',
            :libvirt__iface_name => 'swp52',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:19 --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:19", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:26 --> swp1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:26", NAME="swp1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:2a --> swp2"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:2a", NAME="swp2", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1e --> swp47"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1e", NAME="swp47", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:2c --> swp48"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:2c", NAME="swp48", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:03 --> swp51"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:03", NAME="swp51", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1b --> swp52"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1b", NAME="swp52", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end

  ##### DEFINE VM for wan-2 #####
  config.vm.define "wan-2" do |device|
    device.vm.hostname = "wan-2" 
    device.vm.box = "CumulusCommunity/cumulus-vx"
    device.vm.box_version = "3.5.0"

    device.vm.provider :libvirt do |v|
      v.memory = 768
    end
    #   see note here: https://github.com/pradels/vagrant-libvirt#synced-folders
    device.vm.synced_folder ".", "/vagrant", disabled: true



    # NETWORK INTERFACES
      # link for eth0 --> mgmt-1:swp4
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:23",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '8018',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '9018',
            :libvirt__iface_name => 'eth0',
            auto_config: false
      # link for swp1 --> provider:swp2
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:16",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9011',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8011',
            :libvirt__iface_name => 'swp1',
            auto_config: false
      # link for swp2 --> provider:swp4
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:22",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9017',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8017',
            :libvirt__iface_name => 'swp2',
            auto_config: false
      # link for swp47 --> fw-1:swp3
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:08",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9004',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8004',
            :libvirt__iface_name => 'swp47',
            auto_config: false
      # link for swp48 --> fw-2:swp3
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:0e",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9007',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8007',
            :libvirt__iface_name => 'swp48',
            auto_config: false
      # link for swp51 --> wan-1:swp51
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:04",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9002',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8002',
            :libvirt__iface_name => 'swp51',
            auto_config: false
      # link for swp52 --> wan-1:swp52
      device.vm.network "private_network",
            :mac => "44:38:39:00:00:1c",
            :libvirt__tunnel_type => 'udp',
            :libvirt__tunnel_local_ip => '127.0.0.1',
            :libvirt__tunnel_local_port => '9014',
            :libvirt__tunnel_ip => '127.0.0.1',
            :libvirt__tunnel_port => '8014',
            :libvirt__iface_name => 'swp52',
            auto_config: false



    # Fixes "stdin: is not a tty" and "mesg: ttyname failed : Inappropriate ioctl for device"  messages --> https://github.com/mitchellh/vagrant/issues/1673
    device.vm.provision :shell , inline: "(sudo grep -q 'mesg n' /root/.profile 2>/dev/null && sudo sed -i '/mesg n/d' /root/.profile  2>/dev/null) || true;", privileged: false

    
    # Run the Config specified in the Node Attributes
    device.vm.provision :shell , privileged: false, :inline => 'echo "$(whoami)" > /tmp/normal_user'
    device.vm.provision :shell , path: "./helper_scripts/config_switch.sh"


    # Install Rules for the interface re-map
    device.vm.provision :shell , :inline => <<-delete_udev_directory
if [ -d "/etc/udev/rules.d/70-persistent-net.rules" ]; then
    rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
fi
rm -rfv /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
delete_udev_directory

device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:23 --> eth0"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:23", NAME="eth0", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:16 --> swp1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:16", NAME="swp1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:22 --> swp2"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:22", NAME="swp2", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:08 --> swp47"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:08", NAME="swp47", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:0e --> swp48"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:0e", NAME="swp48", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:04 --> swp51"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:04", NAME="swp51", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     device.vm.provision :shell , :inline => <<-udev_rule
echo "  INFO: Adding UDEV Rule: 44:38:39:00:00:1c --> swp52"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="44:38:39:00:00:1c", NAME="swp52", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
udev_rule
     
      device.vm.provision :shell , :inline => <<-vagrant_interface_rule
echo "  INFO: Adding UDEV Rule: Vagrant interface = eth1"
echo 'ACTION=="add", SUBSYSTEM=="net", ATTR{ifindex}=="2", NAME="eth1", SUBSYSTEMS=="pci"' >> /etc/udev/rules.d/70-persistent-net.rules
echo "#### UDEV Rules (/etc/udev/rules.d/70-persistent-net.rules) ####"
cat /etc/udev/rules.d/70-persistent-net.rules
vagrant_interface_rule

# Run Any Platform Specific Code and Apply the interface Re-map
    #   (may or may not perform a reboot depending on platform)
    device.vm.provision :shell , :inline => $script

end



end