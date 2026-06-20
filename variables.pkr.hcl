variable "vsphere_server" {
  type        = string
  description = "vCenter Server hostname or IP address."
}

variable "vsphere_username" {
  type        = string
  description = "vCenter Server username."
}

variable "vsphere_password" {
  type        = string
  description = "vCenter Server password."
  sensitive   = true
}

variable "vsphere_insecure" {
  type        = bool
  description = "Skip vCenter TLS certificate validation."
  default     = false
}

variable "vsphere_datacenter" {
  type        = string
  description = "vSphere datacenter name."
}

variable "vsphere_cluster" {
  type        = string
  description = "vSphere cluster name. Leave empty when building against a standalone host only."
  default     = ""
}

variable "vsphere_host" {
  type        = string
  description = "ESXi host name or path. Required when the target cluster does not have DRS, or when no cluster is set."
  default     = ""
}

variable "vsphere_resource_pool" {
  type        = string
  description = "Optional resource pool path."
  default     = ""
}

variable "vsphere_datastore" {
  type        = string
  description = "Datastore where the VM is created."
}

variable "vsphere_folder" {
  type        = string
  description = "VM folder where the source object is created."
  default     = ""
}

variable "vsphere_network" {
  type        = string
  description = "Port group for the temporary build VM."
}

variable "vm_name" {
  type        = string
  description = "Source object name. Defaults to rhel-<major>-minimal."
  default     = ""
}

variable "rhel_major" {
  type        = string
  description = "RHEL major version to build: 8, 9, or 10."
  default     = "9"

  validation {
    condition     = contains(["8", "9", "10"], var.rhel_major)
    error_message = "RHEL major version must be one of: 8, 9, 10."
  }
}

variable "rhel8_iso_path" {
  type        = string
  description = "vSphere datastore or content-library path for the RHEL 8 ISO."
  default     = ""
}

variable "rhel8_iso_checksum" {
  type        = string
  description = "Checksum for the RHEL 8 ISO."
  default     = "none"
}

variable "rhel9_iso_path" {
  type        = string
  description = "vSphere datastore or content-library path for the RHEL 9 ISO."
  default     = ""
}

variable "rhel9_iso_checksum" {
  type        = string
  description = "Checksum for the RHEL 9 ISO."
  default     = "none"
}

variable "rhel10_iso_path" {
  type        = string
  description = "vSphere datastore or content-library path for the RHEL 10 ISO."
  default     = ""
}

variable "rhel10_iso_checksum" {
  type        = string
  description = "Checksum for the RHEL 10 ISO."
  default     = "none"
}

variable "rhel8_guest_os_type" {
  type        = string
  description = "vSphere guest OS identifier for RHEL 8."
  default     = "rhel8_64Guest"
}

variable "rhel9_guest_os_type" {
  type        = string
  description = "vSphere guest OS identifier for RHEL 9."
  default     = "rhel9_64Guest"
}

variable "rhel10_guest_os_type" {
  type        = string
  description = "vSphere guest OS identifier for RHEL 10. Defaults to rhel9_64Guest for vCenter compatibility."
  default     = "rhel9_64Guest"
}

variable "ubuntu_release" {
  type        = string
  description = "Ubuntu Server release to build: 24.04 or 26.04."
  default     = "24.04"

  validation {
    condition     = contains(["24.04", "26.04"], var.ubuntu_release)
    error_message = "Ubuntu release must be one of: 24.04, 26.04."
  }
}

variable "ubuntu2404_iso_path" {
  type        = string
  description = "vSphere datastore or content-library path for the Ubuntu Server 24.04 ISO."
  default     = ""
}

variable "ubuntu2404_iso_checksum" {
  type        = string
  description = "Checksum for the Ubuntu Server 24.04 ISO."
  default     = "none"
}

variable "ubuntu2604_iso_path" {
  type        = string
  description = "vSphere datastore or content-library path for the Ubuntu Server 26.04 ISO."
  default     = ""
}

variable "ubuntu2604_iso_checksum" {
  type        = string
  description = "Checksum for the Ubuntu Server 26.04 ISO."
  default     = "none"
}

variable "ubuntu_guest_os_type" {
  type        = string
  description = "vSphere guest OS identifier for Ubuntu Server."
  default     = "ubuntu64Guest"
}

variable "installer_username" {
  type        = string
  description = "Temporary installer/repair account created by Kickstart and used by Packer SSH."
  default     = "breakglass"
}

variable "installer_password" {
  type        = string
  description = "Temporary installer/repair password."
}

variable "installer_password_hash" {
  type        = string
  description = "SHA-512 crypt password hash for Ubuntu autoinstall identity.password."
  default     = ""
}

variable "hostname_domain" {
  type        = string
  description = "Domain suffix used for the temporary installer hostname."
  default     = "localdomain"
}

variable "timezone" {
  type        = string
  description = "System timezone used during installation."
  default     = "UTC"
}

variable "keyboard_layout" {
  type        = string
  description = "Keyboard layout used during installation."
  default     = "us"
}

variable "locale" {
  type        = string
  description = "System locale used during installation."
  default     = "en_US.UTF-8"
}

variable "cpu_count" {
  type        = number
  description = "Number of virtual CPUs."
  default     = 2
}

variable "cpu_cores" {
  type        = number
  description = "Number of cores per socket."
  default     = 1
}

variable "memory_mb" {
  type        = number
  description = "Memory in MiB."
  default     = 4096
}

variable "disk_size_mb" {
  type        = number
  description = "Disk size in MiB."
  default     = 40960
}

variable "disk_thin_provisioned" {
  type        = bool
  description = "Use thin-provisioned disks."
  default     = true
}

variable "firmware" {
  type        = string
  description = "VM firmware: bios, efi, or efi-secure."
  default     = "efi"
}

variable "vm_version" {
  type        = number
  description = "Optional VM hardware version. Set to 0 to let vSphere choose."
  default     = 0
}

variable "convert_to_template" {
  type        = bool
  description = "Convert the source VM to a vSphere template after Packer finishes."
  default     = true
}

variable "boot_wait" {
  type        = string
  description = "How long Packer waits before typing the boot command."
  default     = "5s"
}

variable "boot_command" {
  type        = list(string)
  description = "Boot command used to add the Kickstart URL to the RHEL installer."
  default = [
    "e<wait>",
    "<down><down><end>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rhel.ks",
    "<leftCtrlOn>x<leftCtrlOff>"
  ]
}

variable "ubuntu_boot_command" {
  type        = list(string)
  description = "Boot command used to start Ubuntu Server autoinstall with NoCloud seed data."
  default = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<enter>",
    "initrd /casper/initrd<enter>",
    "boot<enter>"
  ]
}

variable "ssh_timeout" {
  type        = string
  description = "How long Packer waits for SSH after installation."
  default     = "45m"
}

variable "shutdown_timeout" {
  type        = string
  description = "How long Packer waits for shutdown."
  default     = "15m"
}

variable "http_bind_address" {
  type        = string
  description = "Optional local bind address for Packer's Kickstart HTTP server."
  default     = ""
}

variable "http_port_min" {
  type        = number
  description = "Minimum Packer HTTP server port."
  default     = 8000
}

variable "http_port_max" {
  type        = number
  description = "Maximum Packer HTTP server port."
  default     = 9000
}
