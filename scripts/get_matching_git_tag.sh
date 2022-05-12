#!/usr/bin/env bash
set -Exu
set -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Get handy functions
# shellcheck source=bash_functions.sh
source "${DIR}/bash_functions.sh"

## Description:
#   Uses `git describe --exact-match` to get the current tag from branch HEAD.

## Script Function Starts Here ##
export WFP_SILENT=true
if check_if_tag_created; then
  set_env GITHUB_TAG "$(git describe --exact-match)"
  set_output tag "${GITHUB_TAG}"
else
  set_output tag "unknown"
fi
## Script Function Ends Here ##
