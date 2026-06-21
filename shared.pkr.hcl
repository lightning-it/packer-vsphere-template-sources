locals {
  vm_version    = var.vm_version > 0 ? var.vm_version : null
  cluster       = trimspace(var.vsphere_cluster) != "" ? var.vsphere_cluster : null
  host          = trimspace(var.vsphere_host) != "" ? var.vsphere_host : null
  resource_pool = trimspace(var.vsphere_resource_pool) != "" ? var.vsphere_resource_pool : null
  folder        = trimspace(var.vsphere_folder) != "" ? var.vsphere_folder : null
}
