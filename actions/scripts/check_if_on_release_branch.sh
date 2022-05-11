#!/usr/bin/env bash
set -Exu
set -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Get handy functions
# shellcheck source=bash_functions.sh
source "${DIR}/bash_functions.sh"

## Description:
#   Check if the current GITHUB_REF matches the release branch RELEASE_BRANCH.
#   If it does, set step output 'on' to true, and environment variable 'ON_RELEASE_BRANCH' to true.
#   If it doesn't, set step output 'on' to false, and environment variable 'ON_RELEASE_BRANCH' to false.

## Script Function Starts Here ##
if [[ ${GITHUB_REF//refs\/heads\//} == "${RELEASE_BRANCH//refs\/heads\//}" ]]; then
  set_output on true
  set_env ON_RELEASE_BRANCH true
else
  set_output on false
  set_env ON_RELEASE_BRANCH false
fi
## Script Function Ends Here ##
