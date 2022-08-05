#!/usr/bin/env bash
set -Exu
set -o pipefail

## Description:
#   Add description of this script here.

## Script Function Starts Here ##
function get_flyway_sql_path() {
  # If the variable does exist, and the path exists, then just run the migration using that path

  if [[ -n ${FLYWAY_SQL_PATH} ]] && [[ -d ${FLYWAY_SQL_PATH} ]]; then
    local sqlpath="${FLYWAY_SQL_PATH}"
  elif [[ -n ${FLYWAY_SQL_PATH} ]] && [[ -d "${GITHUB_WORKSPACE:-.}/${FLYWAY_SQL_PATH}" ]]; then
    local sqlpath="${GITHUB_WORKSPACE:-.}/${FLYWAY_SQL_PATH}"
  elif [[ -d "${GITHUB_WORKSPACE:-.}/src/main/resources/db/migration" ]]; then
    local sqlpath="${GITHUB_WORKSPACE:-.}/src/main/resources/db/migration"
  else
    error_log "Could not find schema path!"
    exit 1
  fi
  set_env FLYWAY_SQL_PATH "${sqlpath}"
  set_output flyway-sql-path "${sqlpath}"
  notice_log "Schema path: ${FLYWAY_SQL_PATH}"
}
## Script Function Ends Here ##
