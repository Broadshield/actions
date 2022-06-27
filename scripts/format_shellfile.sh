#!/bin/bash
set -e -o pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=scripts/bash_functions.sh
source "${DIR}/bash_functions.sh"

format_shellfile() (
  shopt -s extglob
  local -r usage_text="Usage: $0 <check|format> <file path | folder path>"
  if [[ $# -lt 2 ]]; then
    info_log "${usage_text}"
    exit 1
  fi

  local -r action="$1"
  if [[ ! ${action} =~ (check|format) ]]; then
    error_log "Error: unknown action: $1"
    info_log "${usage_text}"
    exit 1
  fi

  local -r file_or_folder="$2"
  if [[ -d ${file_or_folder} ]]; then
    local -r folder_path="${file_or_folder}"
    local -r file_path="*.sh"
    local -r extra_file_path="*.bash"
  elif [[ -f ${file_or_folder} ]]; then
    local -r file_path="$(basename "${file_or_folder}")"
    local -r folder_path="$(dirname "${file_path}")"
  else
    error_log "Error: ${file_or_folder} is not a file or folder"
    info_log "${usage_text}"
    exit 1
  fi
  if [[ ${action} =~ (check) ]]; then
    local -r checkCommand='shellcheck --color=auto -x --format=tty "$0" || echo "Error: failed to parse ${0}"'
  else
    local -r checkCommand='shellcheck --color=auto --format=diff "$0" | patch "$0" || echo "Error: failed to parse ${0}"'
  fi
  set -x
  find "${folder_path}" -type f \( -name "${file_path}" -o -name "${extra_file_path:-}" \) -exec bash -e -o pipefail -c "${checkCommand}" "{}" \;

)

format_shellfile "$@"
