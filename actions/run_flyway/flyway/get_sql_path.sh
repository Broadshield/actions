#!/usr/bin/env bash
set -Exu
set -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Get handy functions

if ! grep -q 'function' <<<"$(type set_env 2>&1)"; then
  # shellcheck source=../bash_functions.sh
  source "${DIR}/../bash_functions.sh"
fi

## Description:
#   Add description of this script here.

## Script Function Starts Here ##
function get_flyway_sql_path() {
  # If the variable does exist, and the path exists, then just run the migration using that path
  if [[ -d "${FLYWAY_SQL_PATH}" ]]; then
    set_env FLYWAY_SQL_PATH "${FLYWAY_SQL_PATH}"
  elif [[ -d "${GITHUB_WORKSPACE:-.}/${FLYWAY_SQL_PATH}" ]]; then
    set_env FLYWAY_SQL_PATH "${GITHUB_WORKSPACE:-.}/${FLYWAY_SQL_PATH}"
  elif [[ -d "${GITHUB_WORKSPACE:-.}/src/main/resources/db/migration" ]]; then
    set_env FLYWAY_SQL_PATH "${GITHUB_WORKSPACE:-.}/src/main/resources/db/migration"
  else
    error_log "Could not find schema path!"
    exit 1
  fi
  notice_log "Schema path: ${FLYWAY_SQL_PATH}"
}
## Script Function Ends Here ##
