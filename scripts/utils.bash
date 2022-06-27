#!/usr/bin/env bash
set -x -e

function generate_unique_log_file_name() {
  local LOG_PATH="/var/log/platform"
  mkdir -p "${LOG_PATH}"
  if [[ "$1" =~ (silent|-s|-q|quiet) ]]; then
    local SILENT=true
    shift
  else
    local SILENT=false
  fi
  if [[ -n $1 ]]; then
    local MY_NAME="$(basename "$1")"
  else
    local MY_NAME="bash"
  fi

  local LOG_NAME="${MY_NAME%%.*}"
  LOG_NAME="${LOG_NAME//[^a-zA-Z0-9-_]/}"
  CONF_NAME="${LOG_NAME}.conf"
  LOG_NAME_TMP="$(mktemp -p "${LOG_PATH}" -t "${LOG_NAME}.XXXX")"
  LOG_NAME="${LOG_NAME_TMP}.log"

  mv "${LOG_NAME_TMP}" "${LOG_NAME}"

  if [[ "${SILENT}" == "false" ]]; then

    echo "Script for environment ${ENV_NAME} start time: $(date --rfc-3339=seconds)" >"${LOG_NAME}"

    mkdir -p /opt/elasticbeanstalk/tasks/taillogs.d/
    mkdir -p /opt/elasticbeanstalk/tasks/bundlelogs.d/
    echo "${LOG_NAME}" >"/opt/elasticbeanstalk/tasks/bundlelogs.d/${CONF_NAME}"
    echo "${LOG_NAME}" >"/opt/elasticbeanstalk/tasks/taillogs.d/${CONF_NAME}"

  fi

  echo "${LOG_NAME}"
}

function command_exists() {
  command -v "$@" >/dev/null 2>&1
}

function write_env_vars() {
  if ! command_exists curl; then
    yum install -y -q curl
  fi
  if ! command_exists jq; then
    yum install -y -q jq
  fi
  if [[ -f /opt/elasticbeanstalk/bin/get-config ]]; then
    /opt/elasticbeanstalk/bin/get-config environment | jq -r 'to_entries[] | [.key,(.value|@sh)] | "export " + join("=")' >/etc/profile.d/sh.local || true
    chmod +x /etc/profile.d/sh.local
    source /etc/profile.d/sh.local || true
  fi

}
write_env_vars
