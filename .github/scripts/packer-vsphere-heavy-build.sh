#!/usr/bin/env bash
set -euo pipefail

require_env() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "ERROR: required environment variable is empty: ${name}" >&2
    exit 1
  fi
}

iso_key() {
  local kind="$1"
  local version="$2"

  case "${kind}:${version}" in
    rhel:8) printf 'RHEL8' ;;
    rhel:9) printf 'RHEL9' ;;
    rhel:10) printf 'RHEL10' ;;
    ubuntu:24.04) printf 'UBUNTU2404' ;;
    ubuntu:26.04) printf 'UBUNTU2604' ;;
    *)
      echo "ERROR: unsupported Packer build target: ${kind} ${version}" >&2
      exit 2
      ;;
  esac
}

repo_dir="${PACKER_REPO_DIR:-.}"
kind="${PACKER_BUILD_KIND:-rhel}"
version="${PACKER_BUILD_VERSION:-8}"
vm_name="${PACKER_BUILD_VM_NAME:-}"
source_branch="${PACKER_SOURCE_BRANCH:-}"
target_branch="${PACKER_TARGET_BRANCH:-}"

if [ "${source_branch}" != "develop" ] || [ "${target_branch}" != "main" ]; then
  printf 'Skipping heavy Packer build: only develop -> main is allowed (source=%s target=%s).\n' \
    "${source_branch:-unknown}" "${target_branch:-unknown}"
  exit 0
fi

required_common=(
  VSPHERE_SERVER
  VSPHERE_USERNAME
  VSPHERE_PASSWORD
  VSPHERE_DATACENTER
  VSPHERE_DATASTORE
  VSPHERE_NETWORK
  INSTALLER_PASSWORD
)

for name in "${required_common[@]}"; do
  require_env "${name}"
done

if [ -z "${VSPHERE_CLUSTER:-}" ] && [ -z "${VSPHERE_HOST:-}" ]; then
  echo "ERROR: set VSPHERE_CLUSTER or VSPHERE_HOST." >&2
  exit 1
fi

media_prefix="$(iso_key "${kind}" "${version}")"
iso_path_var="${media_prefix}_ISO_PATH"
iso_checksum_var="${media_prefix}_ISO_CHECKSUM"
require_env "${iso_path_var}"
require_env "${iso_checksum_var}"

case "${kind}" in
  rhel)
    vm_name="${vm_name:-rhel-${version}-minimal}"
    ;;
  ubuntu)
    require_env INSTALLER_PASSWORD_HASH
    vm_name="${vm_name:-template-ubuntu-${version%.*}-source}"
    ;;
  *)
    echo "ERROR: PACKER_BUILD_KIND must be rhel or ubuntu." >&2
    exit 2
    ;;
esac

cd "${repo_dir}"

var_file="${RUNNER_TEMP:-/tmp}/packer-vsphere-heavy.pkrvars.hcl"
umask 077
cat > "${var_file}" <<EOF
vsphere_server     = "${VSPHERE_SERVER}"
vsphere_username   = "${VSPHERE_USERNAME}"
vsphere_password   = "${VSPHERE_PASSWORD}"
vsphere_insecure   = ${VSPHERE_INSECURE:-false}
vsphere_datacenter = "${VSPHERE_DATACENTER}"
vsphere_cluster    = "${VSPHERE_CLUSTER:-}"
vsphere_host       = "${VSPHERE_HOST:-}"
vsphere_resource_pool = "${VSPHERE_RESOURCE_POOL:-}"
vsphere_datastore  = "${VSPHERE_DATASTORE}"
vsphere_folder     = "${VSPHERE_FOLDER:-}"
vsphere_network    = "${VSPHERE_NETWORK}"

rhel8_iso_path      = "${RHEL8_ISO_PATH:-}"
rhel8_iso_checksum  = "${RHEL8_ISO_CHECKSUM:-none}"
rhel9_iso_path      = "${RHEL9_ISO_PATH:-}"
rhel9_iso_checksum  = "${RHEL9_ISO_CHECKSUM:-none}"
rhel10_iso_path     = "${RHEL10_ISO_PATH:-}"
rhel10_iso_checksum = "${RHEL10_ISO_CHECKSUM:-none}"

ubuntu2404_iso_path     = "${UBUNTU2404_ISO_PATH:-}"
ubuntu2404_iso_checksum = "${UBUNTU2404_ISO_CHECKSUM:-none}"
ubuntu2604_iso_path     = "${UBUNTU2604_ISO_PATH:-}"
ubuntu2604_iso_checksum = "${UBUNTU2604_ISO_CHECKSUM:-none}"

installer_username      = "${INSTALLER_USERNAME:-breakglass}"
installer_password      = "${INSTALLER_PASSWORD}"
installer_password_hash = "${INSTALLER_PASSWORD_HASH:-}"
EOF

PACKER_SOURCE_BRANCH="${source_branch}" \
PACKER_TARGET_BRANCH="${target_branch}" \
PACKER_BUILD_KIND="${kind}" \
PACKER_BUILD_VERSION="${version}" \
PACKER_BUILD_VM_NAME="${vm_name}" \
PACKER_VAR_FILE="${var_file}" \
scripts/test-packer-heavy.sh
