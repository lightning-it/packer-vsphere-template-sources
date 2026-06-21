#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command not found: $1" >&2
    exit 1
  }
}

bool_value() {
  case "${1:-}" in
    true|TRUE|yes|YES|1|on|ON) printf 'true\n' ;;
    false|FALSE|no|NO|0|off|OFF) printf 'false\n' ;;
    *)
      echo "ERROR: invalid boolean value: ${1:-<empty>}" >&2
      exit 1
      ;;
  esac
}

dns_label_value() {
  printf '%s' "$1" |
    tr '[:upper:]_' '[:lower:]-' |
    sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

instance_name=""
destroy_instance=true

cleanup() {
  local rc="${1:-$?}"

  set +e
  trap - EXIT INT TERM

  if [ -n "${instance_name}" ]; then
    if [ "${rc}" -ne 0 ]; then
      echo "::group::Nested ESXi Incus diagnostics"
      incus list "${instance_name}" --format yaml || true
      incus info "${instance_name}" --show-log || true
      incus config show "${instance_name}" --expanded || true
      incus console "${instance_name}" --show-log || true
      echo "::endgroup::"
    fi

    if [ "${destroy_instance}" = "true" ]; then
      echo "Destroying nested ESXi Incus VM ${instance_name}."
      NESTED_ESXI_INSTANCE_NAME="${instance_name}" \
        ansible-playbook \
          -i localhost, \
          .github/playbooks/nested-esxi.yml \
          -e nested_esxi_state=absent \
        || true
    fi
  fi

  exit "${rc}"
}

trap 'cleanup $?' EXIT INT TERM

require_cmd incus
require_cmd ansible-playbook

repo_dir="${PACKER_REPO_DIR:-.}"
source_branch="${PACKER_SOURCE_BRANCH:-}"
target_branch="${PACKER_TARGET_BRANCH:-}"
run_id="${GITHUB_RUN_ID:-local}"
run_attempt="${GITHUB_RUN_ATTEMPT:-1}"
destroy_instance="$(bool_value "${NESTED_ESXI_DESTROY_INSTANCE:-true}")"

if [ "${source_branch}" != "develop" ] || [ "${target_branch}" != "main" ]; then
  printf 'Skipping nested ESXi heavy Packer build: only develop -> main is allowed (source=%s target=%s).\n' \
    "${source_branch:-unknown}" "${target_branch:-unknown}"
  exit 0
fi

short_run_id="$(dns_label_value "${run_id}")"
short_run_id="${short_run_id: -8}"
instance_name="${NESTED_ESXI_INSTANCE_NAME:-esxi-packer-ci-${short_run_id}-${run_attempt}}"
export NESTED_ESXI_INSTANCE_NAME="${instance_name}"

ansible-playbook \
  -i localhost, \
  .github/playbooks/nested-esxi.yml \
  -e nested_esxi_state=present

export VSPHERE_SERVER="${NESTED_ESXI_ENDPOINT}"
export VSPHERE_USERNAME="${NESTED_ESXI_USERNAME}"
export VSPHERE_PASSWORD="${NESTED_ESXI_PASSWORD}"
export VSPHERE_INSECURE="${NESTED_ESXI_INSECURE:-true}"
export VSPHERE_DATACENTER="${NESTED_ESXI_DATACENTER:-ha-datacenter}"
export VSPHERE_CLUSTER=""
export VSPHERE_HOST="${NESTED_ESXI_ENDPOINT}"
export VSPHERE_RESOURCE_POOL=""
export VSPHERE_DATASTORE="${NESTED_ESXI_DATASTORE:-datastore1}"
export VSPHERE_FOLDER="${NESTED_ESXI_FOLDER:-}"
export VSPHERE_NETWORK="${NESTED_ESXI_NETWORK:-VM Network}"

PACKER_REPO_DIR="${repo_dir}" \
PACKER_SOURCE_BRANCH="${source_branch}" \
PACKER_TARGET_BRANCH="${target_branch}" \
PACKER_BUILD_KIND="${PACKER_BUILD_KIND:-rhel}" \
PACKER_BUILD_VERSION="${PACKER_BUILD_VERSION:-8}" \
PACKER_BUILD_VM_NAME="${PACKER_BUILD_VM_NAME:-}" \
bash "$(dirname "$0")/packer-vsphere-heavy-build.sh"
