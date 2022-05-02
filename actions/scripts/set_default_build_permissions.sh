#!/usr/bin/env bash
set -Exu
set -o pipefail

umask 0022 # Ensure permissions are correct (0755 for dirs, 0644 for files)