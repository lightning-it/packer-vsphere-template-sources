# Agent Instructions

## Repository Purpose

This repository builds first-install Linux template objects for VMware vSphere
with HashiCorp Packer.

Supported first-install object names:

- `rhel-8-minimal`
- `rhel-9-minimal`
- `rhel-10-minimal`
- `template-ubuntu-24-server`
- `template-ubuntu-26-server`

These are first-install objects for later Ansible normalization into final managed
templates such as `template-rhel-8-minimal`, `template-rhel-9-minimal`, and
`template-rhel-10-minimal`, `template-ubuntu-24-server`, and
`template-ubuntu-26-server`.

## Common Practice Rules

- Keep this repository generic and reusable. Do not commit organization-specific values,
  customer hostnames, real vCenter endpoints, real datastore paths, passwords,
  subscription credentials, tokens, or Vault data.
- Keep secrets in ignored local var files or environment variables.
- Keep plugin and tool versions pinned. Do not introduce floating version
  constraints such as `>=`, `~>`, or `latest` for Packer plugins unless the
  user explicitly asks for that behavior.
- Keep RHEL 8, RHEL 9, and RHEL 10 behavior parameterized from the same Packer
  source unless there is a real OS-specific reason to split files.
- Keep Ubuntu Server 24.04 and 26.04 behavior parameterized from the same
  Packer source unless there is a real release-specific reason to split files.
- Keep `breakglass` as the default temporary installer account unless the user
  explicitly requests a different account.
- Use SSH key authentication for Packer guest access. Do not add SSH password
  authentication for the temporary installer account.
- Install `open-vm-tools` during OS installation so VMware guest
  operations work on first boot.
- Keep the Packer-built objects minimal. Final managed users, SSH keys,
  identity cleanup, and final vSphere template readiness belong to the Ansible
  template bootstrap workflow.
- Keep RHEL install automation in Kickstart and Ubuntu install automation in
  autoinstall/cloud-init seed data.

## Packer Tooling

Use HashiCorp Packer only. On some RHEL systems `/usr/sbin/packer` is a
Cracklib utility, not HashiCorp Packer.

Before running Packer commands, check:

```bash
command -v packer
test "$(command -v packer)" != "/usr/sbin/packer"
packer version
```

If HashiCorp Packer is not installed, either install it outside the repo or use
a temporary binary under `/tmp` for validation. Do not vendor downloaded Packer
binaries into this repository.

## Validation

Before finishing changes, run the repository test entry point:

```bash
scripts/test-packer.sh
```

The script is the source of truth for the Packer verification suite. It checks
that `packer` is HashiCorp Packer, syntax-checks the build wrapper scripts,
runs `packer init`, verifies formatting with `packer fmt -check -recursive .`,
and validates the full supported OS matrix:

- RHEL 8, RHEL 9, and RHEL 10 with source names `rhel-<major>-minimal`
- Ubuntu 24.04 and Ubuntu 26.04 with source names
  `template-ubuntu-<major>-source`

Also run whitespace checks before finishing:

```bash
git diff --check
```

The pre-commit configuration runs `scripts/test-packer.sh` for changes to
Packer HCL, installer HTTP templates, example variables, and build/test
scripts. When changing the test matrix or validation policy, update
`scripts/test-packer.sh`, `.pre-commit-config.yaml`, and this section together.

## Heavy Build Verification

A real Packer build is a heavy integration test. It is gated to run only for
the `develop` -> `main` branch flow or manual workflow dispatch. The automated
GitHub Actions path runs on a self-hosted Ubuntu runner with Incus and nested
virtualization labels, creates a temporary nested ESXi VM, runs Packer against
that standalone ESXi API endpoint, and destroys the Incus VM afterward.

It requires a private prepared ESXi Incus image, private runner access,
datastore/network placement, reachable ISO media, and enough time for an
unattended OS install. It creates or refreshes the vSphere source image object,
so do not run it from normal pre-commit.

Use the heavy test wrapper for an intentional image build:

```bash
PACKER_SOURCE_BRANCH=develop \
PACKER_TARGET_BRANCH=main \
PACKER_BUILD_KIND=rhel \
PACKER_BUILD_VERSION=8 \
PACKER_BUILD_VM_NAME=rhel-8-minimal \
PACKER_VAR_FILE=vars/local.pkrvars.hcl \
scripts/test-packer-heavy.sh
```

For Ubuntu:

```bash
PACKER_SOURCE_BRANCH=develop \
PACKER_TARGET_BRANCH=main \
PACKER_BUILD_KIND=ubuntu \
PACKER_BUILD_VERSION=24.04 \
PACKER_BUILD_VM_NAME=template-ubuntu-24-source \
PACKER_VAR_FILE=vars/local.pkrvars.hcl \
scripts/test-packer-heavy.sh
```

The same heavy build is available as a manual pre-commit hook:

```bash
PACKER_SOURCE_BRANCH=develop \
PACKER_TARGET_BRANCH=main \
PACKER_BUILD_KIND=rhel \
PACKER_BUILD_VERSION=8 \
PACKER_VAR_FILE=vars/local.pkrvars.hcl \
pre-commit run packer-heavy-build --hook-stage manual
```

The wrapper checks `PACKER_SOURCE_BRANCH` and `PACKER_TARGET_BRANCH` first.
It also recognizes GitHub Actions `GITHUB_HEAD_REF`/`GITHUB_BASE_REF` and
GitLab merge request variables. If the branch flow is anything other than
`develop` -> `main`, the heavy test exits successfully with a skip message.

The public repository owns the automatic nested ESXi workflow in
`.github/workflows/packer-heavy-nested-esxi.yml`. The workflow must stay guarded
so it does not run on untrusted fork pull requests. The Incus VM lifecycle is
owned by the `lit.supplementary.incus_nested_esxi` collection role and invoked
through `.github/playbooks/nested-esxi.yml`; keep reusable Incus/ESXi lifecycle
logic in that role instead of growing the workflow script. Keep the ESXi Incus
image alias, ESXi credentials, ISO paths, checksums, and installer passwords in
GitHub Actions secrets or repository variables.

Required runner labels:

```text
self-hosted, linux, x64, ubuntu, incus, nested-virt
```

Required secrets:

- `PACKER_NESTED_ESXI_USERNAME`
- `PACKER_NESTED_ESXI_PASSWORD`
- `PACKER_INSTALLER_PASSWORD`
- `PACKER_INSTALLER_PASSWORD_HASH` for Ubuntu builds

Required or commonly used repository variables:

- `PACKER_NESTED_ESXI_INCUS_IMAGE`
- `PACKER_NESTED_ESXI_ENDPOINT`
- `PACKER_NESTED_ESXI_CPU`
- `PACKER_NESTED_ESXI_MEMORY`
- `PACKER_NESTED_ESXI_ROOT_DISK_SIZE`
- `PACKER_NESTED_ESXI_RAW_QEMU`
- `PACKER_NESTED_ESXI_DATASTORE`
- `PACKER_NESTED_ESXI_NETWORK`
- `PACKER_RHEL8_ISO_PATH`
- `PACKER_RHEL8_ISO_CHECKSUM`
- `PACKER_RHEL9_ISO_PATH`
- `PACKER_RHEL9_ISO_CHECKSUM`
- `PACKER_RHEL10_ISO_PATH`
- `PACKER_RHEL10_ISO_CHECKSUM`
- `PACKER_UBUNTU2404_ISO_PATH`
- `PACKER_UBUNTU2404_ISO_CHECKSUM`
- `PACKER_UBUNTU2604_ISO_PATH`
- `PACKER_UBUNTU2604_ISO_CHECKSUM`
- `PACKER_INSTALLER_USERNAME`

In comparison with Ansible tests, `packer validate` is like an Ansible syntax
and input-contract check: it proves the template can be loaded and the required
variables are coherent. `packer build` is closer to a Molecule or integration
run against real infrastructure: it performs the install, creates the vSphere
object, and can fail because of external state such as ISO paths, vCenter
permissions, network reachability, datastore capacity, or guest boot timing.

If the host `packer` command is not HashiCorp Packer, report that limitation.
Use a temporary official Packer binary when practical, but do not vendor Packer
binaries into this repository.

## File Ownership

- Packer plugin pinning belongs in `packer.pkr.hcl`.
- Shared vSphere builder locals belong in `shared.pkr.hcl`.
- RHEL vSphere builder behavior belongs in `rhel.pkr.hcl`.
- Ubuntu vSphere builder behavior belongs in `ubuntu.pkr.hcl`.
- Inputs and defaults belong in `variables.pkr.hcl`.
- Kickstart content belongs in `installer-data/rhel/ks.cfg.pkrtpl.hcl`.
- Ubuntu autoinstall content belongs in `installer-data/ubuntu/`.
- Operator examples belong in `vars/example.pkrvars.hcl`.
- Local operator var files must remain ignored by Git.

## Editing Style

- Use ASCII unless an existing file clearly requires otherwise.
- Keep shell scripts POSIX-friendly where possible, and use Bash intentionally
  when arrays or strict mode are needed.
- Prefer explicit variables and clear validation over hidden environment
  assumptions.
- Keep README examples runnable with the repository layout.
