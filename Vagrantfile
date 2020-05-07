# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.define "proxy" do |proxy|
    proxy.vm.box = "centos/7"
    proxy.vm.network "forwarded_port", guest: 443, host: 443, auto_correct: true
    proxy.vm.hostname = 'proxy'
    proxy.vm.box_url = "centos/7"

    proxy.vm.network :private_network, ip: "192.168.56.101"
    proxy.vm.provision "shell", path:"nginx-proxy-install.sh" 
    proxy.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 512]
      v.customize ["modifyvm", :id, "--name", "proxy"]
    end
  end

  config.vm.define "db" do |db|
    db.vm.box = "generic/ubuntu1804"
    db.vm.network "forwarded_port", guest: 3306, host: 3306, auto_correct: true
    db.vm.hostname = 'db'
    db.vm.box_url = "generic/ubuntu1804"

    db.vm.network :private_network, ip: "192.168.56.103"
    db.vm.provision "shell", inline: <<-SHELL
      sudo sh -c "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf"
      sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
      sudo sysctl net.ipv6.conf.default.disable_ipv6=1
      sudo sysctl net.ipv6.conf.lo.disable_ipv6=1
      sudo systemctl restart systemd-resolved
      sudo apt-get -y update
      sudo apt-get -y remove docker docker-engine docker.io
      sudo apt install -y docker.io
      sudo systemctl start docker
      sudo systemctl enable docker
      sudo docker pull mysql/mysql-server:5.7
      sudo docker run --name=mysqlCon -p 3306:3306 -e MYSQL_ROOT_HOST='%' -e MYSQL_ROOT_PASSWORD=RootPassword -d mysql/mysql-server:5.7
    SHELL
    db.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 1024]
      v.customize ["modifyvm", :id, "--name", "db"]
    end
  end


  config.vm.define "app" do |app|
    app.vm.box = "generic/ubuntu1804"
    app.vm.network "forwarded_port", guest: 8443, host: 8443, auto_correct: true
    app.vm.hostname = 'app'
    app.vm.box_url = "generic/ubuntu1804"

    app.vm.network :private_network, ip: "192.168.56.102"
    app.vm.provision "shell", inline: <<-SHELL
      sudo sh -c "echo 'nameserver 1.1.1.1' >> /etc/resolv.conf"
      sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
      sudo sysctl net.ipv6.conf.default.disable_ipv6=1
      sudo sysctl net.ipv6.conf.lo.disable_ipv6=1
      sudo systemctl restart systemd-resolved
      sudo apt-get -y update
      sudo apt install -y mysql-client
    SHELL
    app.vm.provision "shell", path:"confluence-app-install.sh" 
    app.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 2048]
      v.customize ["modifyvm", :id, "--name", "app"]
    end
  end
end
