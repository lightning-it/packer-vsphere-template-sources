#!/usr/bin/env bash
set -euo pipefail

kind="${PACKER_BUILD_KIND:-}"
version="${PACKER_BUILD_VERSION:-}"
vm_name="${PACKER_BUILD_VM_NAME:-}"
var_file="${PACKER_VAR_FILE:-vars/local.pkrvars.hcl}"
source_branch="${PACKER_SOURCE_BRANCH:-${GITHUB_HEAD_REF:-${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-${CI_COMMIT_REF_NAME:-}}}}"
target_branch="${PACKER_TARGET_BRANCH:-${GITHUB_BASE_REF:-${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}}}"

if [ -z "${source_branch}" ]; then
  source_branch="$(git branch --show-current 2>/dev/null || true)"
fi

if [ "${source_branch}" != "develop" ] || [ "${target_branch}" != "main" ]; then
  printf 'Skipping heavy Packer build: only develop -> main is allowed (source=%s target=%s).\n' \
    "${source_branch:-unknown}" "${target_branch:-unknown}"
  exit 0
fi

usage() {
  cat >&2 <<'EOF'
Usage:
  PACKER_SOURCE_BRANCH=develop PACKER_TARGET_BRANCH=main PACKER_BUILD_KIND=rhel PACKER_BUILD_VERSION=<8|9|10> [PACKER_BUILD_VM_NAME=name] [PACKER_VAR_FILE=vars/local.pkrvars.hcl] scripts/test-packer-heavy.sh
  PACKER_SOURCE_BRANCH=develop PACKER_TARGET_BRANCH=main PACKER_BUILD_KIND=ubuntu PACKER_BUILD_VERSION=<24.04|26.04> [PACKER_BUILD_VM_NAME=name] [PACKER_VAR_FILE=vars/local.pkrvars.hcl] scripts/test-packer-heavy.sh

This is a heavy test. It runs a real Packer build against vSphere and creates
or refreshes a source image object. Use only with a real, ignored var file.
It runs only for develop -> main branch flow.
EOF
}

if [ -z "${kind}" ] || [ -z "${version}" ]; then
  usage
  exit 2
fi

if [ ! -f "${var_file}" ]; then
  printf 'Packer var file not found: %s\n' "${var_file}" >&2
  printf 'Create an ignored local var file with real vSphere and ISO values first.\n' >&2
  exit 2
fi

case "${kind}" in
  rhel)
    case "${version}" in
      8|9|10) ;;
      *)
        printf 'PACKER_BUILD_VERSION for rhel must be 8, 9, or 10.\n' >&2
        exit 2
        ;;
    esac
    vm_name="${vm_name:-rhel-${version}-minimal}"
    scripts/test-packer.sh
    packer build \
      -only='vsphere-iso.rhel' \
      -var-file="${var_file}" \
      -var="rhel_major=${version}" \
      -var="vm_name=${vm_name}" \
      .
    ;;
  ubuntu)
    case "${version}" in
      24.04|26.04) ;;
      *)
        printf 'PACKER_BUILD_VERSION for ubuntu must be 24.04 or 26.04.\n' >&2
        exit 2
        ;;
    esac
    vm_name="${vm_name:-template-ubuntu-${version%.*}-source}"
    scripts/test-packer.sh
    packer build \
      -only='vsphere-iso.ubuntu' \
      -var-file="${var_file}" \
      -var="ubuntu_release=${version}" \
      -var="vm_name=${vm_name}" \
      .
    ;;
  *)
    printf 'PACKER_BUILD_KIND must be rhel or ubuntu.\n' >&2
    exit 2
    ;;
esac
