Vagrant.require_version ">= 1.4.3"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.define :giraph do |giraph|
		giraph.vm.box = "centos65"
		giraph.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.5.1/centos65-x86_64-20131205.box"
		giraph.vm.provider "virtualbox" do |v|
		  v.name = "hadoop-yarn"
		  v.customize ["modifyvm", :id, "--memory", "8192"]
		end
		giraph.vm.network :private_network, ip: "10.211.55.101"
		giraph.vm.hostname = "hadoop-yarn"
		giraph.vm.provision :shell, :path=> 'setup.sh'
		giraph.vm.network "forwarded_port", guest: 50070, host: 50070
		giraph.vm.network "forwarded_port", guest: 50075, host: 50075
		giraph.vm.network "forwarded_port", guest: 8088, host: 8088
		giraph.vm.network "forwarded_port", guest: 8042, host: 8042
		giraph.vm.network "forwarded_port", guest: 19888, host: 19888
	end
end
