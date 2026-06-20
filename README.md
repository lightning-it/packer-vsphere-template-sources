# packer-base-vsphere

Packer templates to build hardened, reusable Linux source templates on VMware
vSphere from vendor installation ISO media.

This repository builds RHEL 8/9/10 and Ubuntu Server 24.04/26.04 source
objects.

## Purpose

Use Packer for the first unattended operating system installation from ISO.
Then hand the installed source object to the Ansible vSphere template runbooks
for managed user creation, identity cleanup, power-off, and template
conversion.

Recommended split:

- Packer does the first OS install from ISO.
- RHEL 8, RHEL 9, and RHEL 10 use Packer plus Kickstart.
- Ubuntu Server 24.04 and 26.04 use Packer plus autoinstall/cloud-init seed
  data.
- `open-vm-tools` is installed during OS installation so VMware guest
  operations work immediately after first boot.
- Packer produces source objects such as `rhel-8-minimal`, `rhel-9-minimal`,
  `rhel-10-minimal`, `template-ubuntu-24-source`, and
  `template-ubuntu-26-source`.
- Ansible clones or bootstraps those sources into final templates such as
  `template-rhel-8-minimal`, `template-rhel-9-minimal`,
  `template-rhel-10-minimal`, `template-ubuntu-24-server`, and
  `template-ubuntu-26-server`.

The source object may keep a temporary installer or repair login. The final
template bootstrap account, for example `breakglass`, is managed by Ansible
after the OS install is complete.

## Source Object Contract

| OS | Source object | Install automation | Final template |
| --- | --- | --- | --- |
| RHEL 8 | `rhel-8-minimal` | Kickstart | `template-rhel-8-minimal` |
| RHEL 9 | `rhel-9-minimal` | Kickstart | `template-rhel-9-minimal` |
| RHEL 10 | `rhel-10-minimal` | Kickstart | `template-rhel-10-minimal` |
| Ubuntu Server 24.04 | `template-ubuntu-24-source` | autoinstall/cloud-init | `template-ubuntu-24-server` |
| Ubuntu Server 26.04 | `template-ubuntu-26-source` | autoinstall/cloud-init | `template-ubuntu-26-server` |

Do not reuse a source object whose installed OS does not match its name. Rebuild
or replace the source first.

## Expected Packer Inputs

The implementation should accept these values through variable files or
environment variables:

- vCenter hostname, username, password, datacenter, cluster, datastore, folder,
  and network
- VM name for the source object
- guest OS type for vSphere
- ISO path or ISO URL
- ISO checksum
- CPU, memory, disk size, firmware, and secure boot settings
- temporary installer username and password or root password
- RHEL major version for Kickstart selection or Ubuntu release selection
- optional content library or template folder placement

Secrets must stay out of Git. Use ignored local var files or environment
variables.

## Repository Layout

```text
.
|-- .gitignore
|-- README.md
|-- http/
|   |-- rhel/
|   |   `-- ks.cfg.pkrtpl.hcl
|   `-- ubuntu/
|       |-- meta-data.pkrtpl.hcl
|       `-- user-data.pkrtpl.hcl
|-- packer.pkr.hcl
|-- rhel.pkr.hcl
|-- shared.pkr.hcl
|-- scripts/
|   |-- build-rhel.sh
|   `-- build-ubuntu.sh
|-- ubuntu.pkr.hcl
|-- variables.pkr.hcl
`-- vars/
    `-- example.pkrvars.hcl
```

## Build Flow

Install HashiCorp Packer `1.14.0` or newer. The repository pins the VMware
vSphere plugin to `github.com/vmware/vsphere` version `2.2.0`.

On some RHEL systems `/usr/sbin/packer` is a Cracklib utility, not HashiCorp
Packer. Check the binary before running raw Packer commands:

```bash
command -v packer
test "$(command -v packer)" != "/usr/sbin/packer"
packer version
```

Create a local variable file:

```bash
cp vars/example.pkrvars.hcl vars/local.pkrvars.hcl
chmod 0600 vars/local.pkrvars.hcl
```

Edit `vars/local.pkrvars.hcl` and replace the vCenter, placement, ISO,
checksum, installer password, and Ubuntu password hash values. The local file
is ignored by Git.

Validate the project:

```bash
packer init .
packer fmt -check -recursive .
packer validate -var-file=vars/local.pkrvars.hcl .
```

Build each RHEL source object:

```bash
./scripts/build-rhel.sh 8
./scripts/build-rhel.sh 9
./scripts/build-rhel.sh 10
```

Build each Ubuntu Server source object:

```bash
./scripts/build-ubuntu.sh 24.04
./scripts/build-ubuntu.sh 26.04
```

The wrapper runs `packer init`, `packer validate`, and `packer build`. To use a
different var file:

```bash
PACKER_VAR_FILE=vars/lit.local.pkrvars.hcl ./scripts/build-rhel.sh 9
PACKER_VAR_FILE=vars/lit.local.pkrvars.hcl ./scripts/build-ubuntu.sh 24.04
```

## Installer Requirements

RHEL Kickstart must:

- install a minimal package set
- install and enable `open-vm-tools`
- enable networking
- create or enable the temporary repair login needed by the bootstrap runbook
- configure SSH enough for troubleshooting
- clean package caches before shutdown
- shut down cleanly when provisioning finishes

Ubuntu autoinstall must:

- install Ubuntu Server
- install and enable `open-vm-tools`
- install and enable OpenSSH Server
- create or enable the temporary repair login needed by the bootstrap runbook
- set passwordless sudo for the temporary repair login
- clean package caches before shutdown
- reboot into the installed system so Packer can verify SSH and VMware Tools

## vSphere Placement Notes

Set either:

- `vsphere_cluster` for a DRS-enabled cluster
- `vsphere_cluster` and `vsphere_host` for a cluster without DRS
- `vsphere_host` for a standalone ESXi host

Set `vsphere_resource_pool` only when the build should use a non-root resource
pool.

RHEL 10 defaults to `rhel9_64Guest` because some vCenter/ESXi versions do not
yet expose a RHEL 10 guest ID. Override `rhel10_guest_os_type` if your vCenter
supports a better identifier.

The Ansible template bootstrap runbook remains responsible for final managed
users, including `breakglass`, SSH authorization, identity cleanup, and marking
the final object as a reusable vSphere template.
