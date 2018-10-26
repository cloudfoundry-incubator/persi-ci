#!/usr/bin/env bash

set -e -x

function get_password_from_credhub() {
  local bosh_manifest_password_variable_name=$1
  credhub find -j -n "${bosh_manifest_password_variable_name}" | jq -r .credentials[].name | xargs credhub get -j -n | jq -r .value
}

function setup_bosh_env_vars() {
  set +x
  pushd "director-state/${BBL_STATE_DIR}"
    eval "$(bbl print-env)"
  popd
  set -x
}

function validate_required_params() {
  # Required standard CATs config fields
  check_param APPS_DOMAIN
  check_param CF_API_ENDPOINT
  check_param CF_USERNAME

  # Required PATs config fields
  check_param PLAN_NAME
  check_param SERVICE_NAME
}

function write_config_to_file() {
  CONFIG_FILE="pats-config/pats.json"
  cat << EOF > ${CONFIG_FILE}
{
  "admin_password": "$(get_password_from_credhub cf_admin_password)",
  "admin_user": "${CF_USERNAME}",
  "api": "${CF_API_ENDPOINT}",
  "apps_domain": "${APPS_DOMAIN}",
  "default_timeout": 30,
  "name_prefix": "$(openssl rand -hex 3)",
  "skip_ssl_validation": true,

  "bind_bogus_config": "${BIND_BOGUS_CONFIG}",
  "bind_config": "${BIND_CONFIG}",
  "broker_url": "${BROKER_URL}",
  "broker_user": "${BROKER_USER}",
  "create_bogus_config": "${CREATE_BOGUS_CONFIG}",
  "create_config": "${CREATE_CONFIG}",
  "create_lazy_unmount_config": "${CREATE_LAZY_UNMOUNT_CONFIG}",
  "disallowed_ldap_bind_config": "${DISALLOWED_LDAP_BIND_CONFIG}",
  "isolation_segment": "${TEST_ISOLATION_SEGMENT}",
  "lazy_unmount_vm_instance": "${LAZY_UNMOUNT_VM_INSTANCE}",
  "plan_name": "${PLAN_NAME}",
  "service_name": "${SERVICE_NAME}"
}
EOF

  if [[ -n "${BROKER_PASSWORD_KEY}" ]]; then
    broker_password="$(get_password_from_credhub "${BROKER_PASSWORD_KEY}")"
    new_config=$(cat "${CONFIG_FILE}" | jq ".broker_password=\"${broker_password}\"")
    echo "${new_config}" > "${CONFIG_FILE}"
  fi
}

scripts_path="$(dirname $0)"
source "${scripts_path}/utils.sh"

# This config file contains fields from both the standard CATs config AND
# the PATs config structs.

setup_bosh_env_vars
validate_required_params
write_config_to_file
