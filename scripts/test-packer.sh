#!/usr/bin/env bash
set -euo pipefail

if ! command -v packer >/dev/null 2>&1; then
  printf 'HashiCorp Packer was not found in PATH.\n' >&2
  exit 127
fi

packer_path="$(command -v packer)"
if [ "${packer_path}" = "/usr/sbin/packer" ]; then
  printf '/usr/sbin/packer is not HashiCorp Packer on this host.\n' >&2
  printf 'Install HashiCorp Packer or place it earlier in PATH.\n' >&2
  exit 127
fi

if ! packer version 2>/dev/null | grep -q 'Packer v'; then
  printf 'The packer command in PATH does not appear to be HashiCorp Packer.\n' >&2
  printf 'Install HashiCorp Packer or adjust PATH before running this script.\n' >&2
  exit 127
fi

bash -n scripts/build-rhel.sh
bash -n scripts/build-ubuntu.sh

packer init .
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
