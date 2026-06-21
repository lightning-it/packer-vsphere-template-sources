# Copy to vars/local.pkrvars.hcl and replace all environment-specific values.
# vars/local.pkrvars.hcl is ignored by Git.

vsphere_server     = "vcenter.example.com"
vsphere_username   = "administrator@vsphere.local"
vsphere_password   = "REPLACE-ME"
vsphere_insecure   = true
vsphere_datacenter = "Datacenter"
vsphere_cluster    = "Cluster"
vsphere_host       = ""
vsphere_datastore  = "datastore1"
vsphere_folder     = "templates"
vsphere_network    = "VM Network"

rhel8_iso_path      = "[datastore1] iso/rhel-8.x-x86_64-dvd.iso"
rhel8_iso_checksum  = "sha256:REPLACE-ME"
rhel9_iso_path      = "[datastore1] iso/rhel-9.x-x86_64-dvd.iso"
rhel9_iso_checksum  = "sha256:REPLACE-ME"
rhel10_iso_path     = "[datastore1] iso/rhel-10.x-x86_64-dvd.iso"
rhel10_iso_checksum = "sha256:REPLACE-ME"

ubuntu2404_iso_path     = "[datastore1] iso/ubuntu-24.04-live-server-amd64.iso"
ubuntu2404_iso_checksum = "sha256:REPLACE-ME"
ubuntu2604_iso_path     = "[datastore1] iso/ubuntu-26.04-live-server-amd64.iso"
ubuntu2604_iso_checksum = "sha256:REPLACE-ME"

installer_username = "breakglass"

# Real builds require a readable private key and the matching public key.
# Leave these empty only for `packer validate`.
installer_private_key_file = ""
installer_authorized_keys  = []

# Ubuntu still requires an identity password field. Keep it locked by default.
installer_password_hash = "!"
