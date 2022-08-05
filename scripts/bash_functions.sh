#!/usr/bin/env bash
set -e
if [[ -z ${BFD_REPOSITORY:-} ]]; then
  if [[ -x "/home/bitflight-devops/.shell-scripts" ]]; then
    export BFD_REPOSITORY="/home/bitflight-devops/.shell-scripts"
  elif [[ -x "${HOME}/.shell-scripts" ]]; then
    export BFD_REPOSITORY="${HOME}/.shell-scripts"
  elif [[ -x "${HOME}/.cache/.shell-scripts" ]]; then
    export BFD_REPOSITORY="${HOME}/.cache/.shell-scripts"
  elif [[ -x "/usr/local/.shell-scripts" ]]; then
    export BFD_REPOSITORY="/usr/local/.shell-scripts"
  elif [[ -x "/opt/bitflight-devops/.shell-scripts" ]]; then
    export BFD_REPOSITORY="/opt/bitflight-devops/.shell-scripts"
  fi
fi

# If the scripts haven't been loaded from another script, load them
if [[ -z ${SHELL_SCRIPTS_BOOTSTRAP_LOADED:-} ]]; then
  export SHELL_SCRIPTS_QUIET=1
  # Is the script library available
  if [[ -z ${BFD_REPOSITORY:-} ]]; then
    is_darwin() { uname -s | grep -q -i darwin; }
    if command -v curl >/dev/null 2>&1; then
      if is_darwin; then
        script_dir="$(mktemp -d)"
        curl -s -L -o "${script_dir}/install.sh" "https://raw.githubusercontent.com/bitflight-devops/shell-scripts/main/install.sh"
        chmod +x "${script_dir}/install.sh"
        NONINTERACTIVE=1 source "${script_dir}/install.sh"
      else
        NONINTERACTIVE=1 source <(curl -sL "https://raw.githubusercontent.com/bitflight-devops/shell-scripts/main/install.sh") || true
      fi
    elif command -v wget >/dev/null 2>&1; then
      if is_darwin; then
        script_dir="$(mktemp -d)"
        wget -q -O "${script_dir}/install.sh" "https://raw.githubusercontent.com/bitflight-devops/shell-scripts/main/install.sh"
        chmod +x "${script_dir}/install.sh"
        NONINTERACTIVE=1 source "${script_dir}/install.sh"
      else
        NONINTERACTIVE=1 source <(wget -q "https://raw.githubusercontent.com/bitflight-devops/shell-scripts/main/install.sh" -O -) || true
      fi
    fi
  fi
  if [[ -n ${BFD_REPOSITORY:-} ]] && [[ -x ${BFD_REPOSITORY} ]]; then
    SCRIPTS_LIB_DIR="${BFD_REPOSITORY}/lib"
  fi
  if [[ -n ${SCRIPTS_LIB_DIR} ]]; then
    NONINTERACTIVE=1 source "${SCRIPTS_LIB_DIR}/bootstrap.sh" || true
  else
    echo "Failed to run bootstrap.sh"
    echo "Please install the shell-scripts repository from github.com/bitflight-devops/shell-scripts"
  fi
fi
