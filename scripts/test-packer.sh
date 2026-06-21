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

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT INT TERM

test_key="${tmp_dir}/packer-validate-key"
ssh-keygen -q -t ed25519 -N "" -C "packer-validate@example.invalid" -f "${test_key}"
test_pub_key="$(cat "${test_key}.pub")"

packer init .
packer fmt -check -recursive .

for major in 8 9 10; do
  packer validate \
    -var-file=vars/example.pkrvars.hcl \
    -var="rhel_major=${major}" \
    -var="vm_name=rhel-${major}-minimal" \
    -var="installer_private_key_file=${test_key}" \
    -var="installer_authorized_keys=[\"${test_pub_key}\"]" \
    .
done

for release in 24.04 26.04; do
  packer validate \
    -var-file=vars/example.pkrvars.hcl \
    -var="ubuntu_release=${release}" \
    -var="vm_name=template-ubuntu-${release%.*}-server" \
    -var="installer_private_key_file=${test_key}" \
    -var="installer_authorized_keys=[\"${test_pub_key}\"]" \
    .
done
