$provisioning_script = <<-'SCRIPT'
#!/bin/bash
set -o nounset errexit
sudo su 
echo "Adding public ssh key to root..."
install -m=600 /home/vagrant/pubkey.pub /root/.ssh/authorized_keys
rm /home/vagrant/pubkey.pub
dnf -y upgrade
dnf -y install \
    java-11-openjdk-devel \
    maven \
    git
echo "Done! Rebooting in 5 seconds"
sleep 5
reboot
SCRIPT

Vagrant.configure("2") do |config|
    config.vm.box = "fedora/33-cloud-base"
    config.vm.box_version = "33.20201019.0"
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/home/vagrant/pubkey.pub"
    config.vm.provision "shell", inline: $provisioning_script
    config.vm.provider "virtualbox" do |v|
        v.name = "fedora_33"
        v.cpus = 4
        v.memory = 8192 
      end
  end
