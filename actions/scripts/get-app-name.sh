#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Get handy functions
# shellcheck source=bash_functions.sh
source "${DIR}/bash_functions.sh"

if [[ -f "${GITHUB_WORKSPACE}/.elasticbeanstalk/config.yml" ]]; then
  eval "$(parse_yaml .elasticbeanstalk/config.yml | grep global_application_name)"
else
  error_log "No config.yml found in ${GITHUB_WORKSPACE}/.elasticbeanstalk"
  exit 1
fi

function remove_env_from_application_name() {
  local app_name="${1}"
  node "${DIR}/get-app-name.js" "${app_name}"
}

#shellcheck disable=SC2154
set_env APPLICATION_PREFIX "$(remove_env_from_application_name "${global_application_name}")"
set_output app_prefix "${APPLICATION_PREFIX}"
export GITHUB_LOG_TITLE="Elastic Beanstalk Application name"
notice_log "\`${APPLICATION_PREFIX}\`"
unset GITHUB_LOG_TITLE
