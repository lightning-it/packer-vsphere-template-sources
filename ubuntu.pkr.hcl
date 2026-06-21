locals {
  ubuntu_media = {
    "24.04" = {
      iso_path     = var.ubuntu2404_iso_path
      iso_checksum = var.ubuntu2404_iso_checksum
      short_name   = "24"
    }
    "26.04" = {
      iso_path     = var.ubuntu2604_iso_path
      iso_checksum = var.ubuntu2604_iso_checksum
      short_name   = "26"
    }
  }

  ubuntu                        = local.ubuntu_media[var.ubuntu_release]
  ubuntu_vm_name                = trimspace(var.vm_name) != "" ? var.vm_name : "template-ubuntu-${local.ubuntu.short_name}-server"
  ubuntu_hostname               = replace(local.ubuntu_vm_name, "_", "-")
  ubuntu_static_network_enabled = trimspace(var.ubuntu_installer_ip) != "" && trimspace(var.ubuntu_installer_netmask) != "" && trimspace(var.ubuntu_installer_gateway) != "" && trimspace(var.ubuntu_installer_prefix) != ""
  ubuntu_boot_command_effective = [
    "e<wait5>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud",
    "<leftCtrlOn>x<leftCtrlOff>"
  ]
}

source "vsphere-iso" "ubuntu" {
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_username
  password            = var.vsphere_password
  insecure_connection = var.vsphere_insecure
  datacenter          = var.vsphere_datacenter

  cluster       = local.cluster
  host          = local.host
  resource_pool = local.resource_pool
  datastore     = var.vsphere_datastore
  folder        = local.folder
  vm_name       = local.ubuntu_vm_name

  guest_os_type = var.ubuntu_guest_os_type
  vm_version    = local.vm_version
  firmware      = var.firmware

  CPUs      = var.cpu_count
  cpu_cores = var.cpu_cores
  RAM       = var.memory_mb

  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = var.disk_size_mb
    disk_thin_provisioned = var.disk_thin_provisioned
  }

  network_adapters {
    network      = var.vsphere_network
    network_card = "vmxnet3"
  }

  iso_paths    = [local.ubuntu.iso_path]
  iso_checksum = local.ubuntu.iso_checksum
  cdrom_type   = "sata"
  remove_cdrom = true

  cd_label = "cidata"
  cd_content = {
    "meta-data" = templatefile("${path.root}/installer-data/ubuntu/meta-data.pkrtpl.hcl", {
      instance_id = local.ubuntu_vm_name
      host_name   = local.ubuntu_hostname
    })
    "user-data" = templatefile("${path.root}/installer-data/ubuntu/user-data.pkrtpl.hcl", {
      ubuntu_release            = var.ubuntu_release
      vm_name                   = local.ubuntu_vm_name
      host_name                 = local.ubuntu_hostname
      installer_username        = var.installer_username
      installer_password_hash   = var.installer_password_hash
      installer_authorized_keys = var.installer_authorized_keys
      timezone                  = var.timezone
      keyboard_layout           = var.keyboard_layout
      locale                    = var.locale
      static_network_enabled    = local.ubuntu_static_network_enabled
      installer_interface       = var.ubuntu_installer_interface
      installer_ip              = var.ubuntu_installer_ip
      installer_prefix          = var.ubuntu_installer_prefix
      installer_gateway         = var.ubuntu_installer_gateway
      installer_nameserver      = var.ubuntu_installer_nameserver
      secondary_interface       = var.ubuntu_installer_secondary_interface
      secondary_ip              = var.ubuntu_installer_secondary_ip
    })
  }

  boot_wait    = var.boot_wait
  boot_command = local.ubuntu_boot_command_effective

  communicator         = "ssh"
  ssh_username         = var.installer_username
  ssh_private_key_file = var.installer_private_key_file
  ssh_timeout          = var.ssh_timeout

  shutdown_command = "sudo -n /sbin/shutdown -h now"
  shutdown_timeout = var.shutdown_timeout

  convert_to_template = var.convert_to_template
  tools_sync_time     = true

  configuration_parameters = {
    "disk.EnableUUID" = "TRUE"
  }
}

build {
  name    = "ubuntu-${var.ubuntu_release}-server-vsphere"
  sources = ["source.vsphere-iso.ubuntu"]

  provisioner "shell" {
    inline = [
      "set -eux",
      "test -x /usr/bin/vmtoolsd || test -x /usr/sbin/vmtoolsd",
      "systemctl is-enabled open-vm-tools || systemctl is-enabled vmtoolsd",
      "systemctl is-enabled ssh",
      "sudo apt-get clean"
    ]
  }
}
