#!/usr/bin/env bash
sourced=0
if [[ -n "${ZSH_EVAL_CONTEXT}" ]]; then
  # shellcheck disable=SC2249
  case ${ZSH_EVAL_CONTEXT} in *:file) sourced=1 ;; esac
elif [[ -n "${BASH_VERSION}" ]]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  # shellcheck disable=SC2249
  case ${0##*/} in sh | dash) sourced=1 ;; esac
fi

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists timeout; then
  command_exists brew && brew install coreutils
fi
if ! command_exists timeout; then
  command_exists gtimeout && alias timeout=gtimeout
fi
[[ $(type -t info_log) == function ]] || function info_log { echo "$@" >&2; }
[[ $(type -t error_log) == function ]] || function error_log { echo "$@" >&2; }
command_exists gtimeout && TIMEOUT_OPTION="--preserve-status"

function wait_for_port() {
  PORT_TIMEOUT="${PORT_TIMEOUT:-10}"
  info_log "⏳  Waiting up to ${PORT_TIMEOUT} seconds for port ${2} to become available for connection on host ${1} sending message '${3}'"
  start=$(date +%s)
  # shellcheck disable=SC2016,SC2248
  if timeout ${TIMEOUT_OPTION:-} "${PORT_TIMEOUT}" bash -c 'until printf "$2" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 1; done' "${1}" "${2}" "${3}"; then
    info_log "✅  Port ${2} on host ${1} is open. Time taken: $(($(date +%s) - start)) seconds"
  else
    error_log "❌  Port ${2} on host ${1} is not available."
    return 1
  fi
}
# If not sourced then run with the arguments
# shellcheck disable=SC2248
if [[ ${sourced} -eq 0 ]]; then
  wait_for_port "$@"
fi
