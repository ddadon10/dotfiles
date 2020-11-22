Vagrant.configure("2") do |config|
    config.vm.box = "centos/8"
    config.vm.box_version = "1905.1"
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/home/vagrant/.ssh/pubkey.pub"
    config.vm.provision "shell", inline: "cat /home/vagrant/.ssh/pubkey.pub >> /home/vagrant/.ssh/authorized_keys"
    config.vm.provision "shell", inline: "rm -f /home/vagrant/.ssh/pubkey.pub"
    config.vm.provider "virtualbox" do |v|
        v.name = "centos_8"
        v.cpus = 4
        v.memory = 8192 
      end
  end
