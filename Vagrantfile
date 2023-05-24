# -*- mode: ruby -*-
# vi: set ft=ruby :

box = ENV["BOX_NAME"]

Vagrant.configure("2") do |config|
  config.vm.box = box.to_s

  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 2
    libvirt.memory = 2048
  end

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "4096"
  end

  config.ssh.insert_key = false
  config.ssh.connect_timeout = 60
  config.ssh.extra_args = ["-o", "PreferredAuthentications=publickey"]
  # config.ssh.password = "vagrant"

  config.nfs.verify_installed = false
  config.vm.synced_folder '.', '/vagrant', disabled: true
  # config.vm.synced_folder ".", "/vagrant",
  # type: "nfs",
  # nfs_udp: false,
  # mount_options: ['nolock']

end
