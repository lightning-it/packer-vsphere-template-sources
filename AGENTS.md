# Agent Instructions

## Repository Purpose

This repository builds first-install Linux source objects for VMware vSphere
with HashiCorp Packer.

Supported source object names:

- `rhel-8-minimal`
- `rhel-9-minimal`
- `rhel-10-minimal`
- `template-ubuntu-24-source`
- `template-ubuntu-26-source`

These are source objects for later Ansible normalization into final managed
templates such as `template-rhel-8-minimal`, `template-rhel-9-minimal`, and
`template-rhel-10-minimal`, `template-ubuntu-24-server`, and
`template-ubuntu-26-server`.

## Common Practice Rules

- Keep this repository generic and reusable. Do not commit LIT-only values,
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
- Do not reintroduce `litadm` as a default account.
- Install `open-vm-tools` during OS installation so VMware guest
  operations work on first boot.
- Keep the Packer source objects minimal. Final managed users, SSH keys,
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

Before finishing changes, run:

```bash
git diff --check
bash -n scripts/build-rhel.sh
bash -n scripts/build-ubuntu.sh
packer fmt -check -recursive .
for major in 8 9 10; do
  packer validate \
    -var-file=vars/example.pkrvars.hcl \
    -var="rhel_major=${major}" \
    -var="vm_name=rhel-${major}-minimal" \
    .
done
for release in 24.04 26.04; do
  packer validate \
    -var-file=vars/example.pkrvars.hcl \
    -var="ubuntu_release=${release}" \
    -var="vm_name=template-ubuntu-${release%.*}-source" \
    .
done
```

If the host `packer` command is not HashiCorp Packer, report that limitation
and use a temporary official Packer binary when practical.

## File Ownership

- Packer plugin pinning belongs in `packer.pkr.hcl`.
- Shared vSphere builder locals belong in `shared.pkr.hcl`.
- RHEL vSphere builder behavior belongs in `rhel.pkr.hcl`.
- Ubuntu vSphere builder behavior belongs in `ubuntu.pkr.hcl`.
- Inputs and defaults belong in `variables.pkr.hcl`.
- Kickstart content belongs in `http/rhel/ks.cfg.pkrtpl.hcl`.
- Ubuntu autoinstall content belongs in `http/ubuntu/`.
- Operator examples belong in `vars/example.pkrvars.hcl`.
- Local operator var files must remain ignored by Git.

## Editing Style

- Use ASCII unless an existing file clearly requires otherwise.
- Keep shell scripts POSIX-friendly where possible, and use Bash intentionally
  when arrays or strict mode are needed.
- Prefer explicit variables and clear validation over hidden environment
  assumptions.
- Keep README examples runnable with the repository layout.
