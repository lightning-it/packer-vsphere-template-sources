#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s <24.04|26.04> [vm-name]\n' "$0" >&2
  exit 2
fi

release="$1"
case "${release}" in
  24.04) default_name="template-ubuntu-24-source" ;;
  26.04) default_name="template-ubuntu-26-source" ;;
  *)
    printf 'Ubuntu release must be 24.04 or 26.04.\n' >&2
    exit 2
    ;;
esac

vm_name="${2:-${default_name}}"
var_file="${PACKER_VAR_FILE:-vars/local.pkrvars.hcl}"

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

test -f "${var_file}"

packer init .
packer validate \
  -var-file="${var_file}" \
  -var="ubuntu_release=${release}" \
  -var="vm_name=${vm_name}" \
  .
packer build \
  -only='vsphere-iso.ubuntu' \
  -var-file="${var_file}" \
  -var="ubuntu_release=${release}" \
  -var="vm_name=${vm_name}" \
  .
