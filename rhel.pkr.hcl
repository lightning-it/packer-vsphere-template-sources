locals {
  rhel_media = {
    "8" = {
      iso_path      = var.rhel8_iso_path
      iso_checksum  = var.rhel8_iso_checksum
      guest_os_type = var.rhel8_guest_os_type
    }
    "9" = {
      iso_path      = var.rhel9_iso_path
      iso_checksum  = var.rhel9_iso_checksum
      guest_os_type = var.rhel9_guest_os_type
    }
    "10" = {
      iso_path      = var.rhel10_iso_path
      iso_checksum  = var.rhel10_iso_checksum
      guest_os_type = var.rhel10_guest_os_type
    }
  }

  rhel      = local.rhel_media[var.rhel_major]
  vm_name   = trimspace(var.vm_name) != "" ? var.vm_name : "rhel-${var.rhel_major}-minimal"
  host_name = trimspace(var.rhel_installer_hostname) != "" ? var.rhel_installer_hostname : replace(local.vm_name, "_", "-")
  rhel_networks = [
    for network_name in [var.vsphere_network, var.vsphere_network_secondary] :
    network_name if trimspace(network_name) != ""
  ]
}

source "vsphere-iso" "rhel" {
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
  vm_name       = local.vm_name

  guest_os_type = local.rhel.guest_os_type
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

  dynamic "network_adapters" {
    for_each = local.rhel_networks
    content {
      network      = network_adapters.value
      network_card = "vmxnet3"
    }
  }

  iso_paths    = [local.rhel.iso_path]
  iso_checksum = local.rhel.iso_checksum
  cdrom_type   = "sata"
  remove_cdrom = true

  cd_label = "OEMDRV"
  cd_content = {
    "/rhel.ks" = templatefile("${path.root}/installer-data/rhel/ks.cfg.pkrtpl.hcl", {
      rhel_major                = var.rhel_major
      vm_name                   = local.vm_name
      host_name                 = local.host_name
      hostname_domain           = var.hostname_domain
      installer_username        = var.installer_username
      installer_authorized_keys = var.installer_authorized_keys
      rhsm_organization         = var.rhsm_organization
      rhsm_activation_key       = var.rhsm_activation_key
      installer_ip              = var.rhel_installer_ip
      installer_netmask         = var.rhel_installer_netmask
      installer_gateway         = var.rhel_installer_gateway
      installer_nameserver      = var.rhel_installer_nameserver
      installer_secondary_ip    = var.rhel_installer_secondary_ip
      timezone                  = var.timezone
      keyboard_layout           = var.keyboard_layout
      locale                    = var.locale
    })
  }

  boot_wait    = var.boot_wait
  boot_command = var.boot_command

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
  name    = "rhel-${var.rhel_major}-vsphere"
  sources = ["source.vsphere-iso.rhel"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "test -x /usr/bin/vmtoolsd || test -x /usr/sbin/vmtoolsd",
      "systemctl is-enabled vmtoolsd",
      "systemctl is-enabled sshd",
      "sudo dnf -y clean all"
    ]
  }
}
