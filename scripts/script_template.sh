#!/usr/bin/env bash
set -Exu
set -o pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Get handy functions
if ! grep -q 'function' <<<"$(type set_env 2>&1)"; then
  # shellcheck source=./bash_functions.sh
  source "${DIR}/bash_functions.sh"
fi

## Description:
#   Add description of this script here.

## Script Function Starts Here ##

## Script Function Ends Here ##
