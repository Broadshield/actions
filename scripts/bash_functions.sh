#!/usr/bin/env bash

# if [ -n "${BASH_FUNCTIONS_LOADED}" ]; then
#     exit 0
# fi
set +x
if [[ ${DEBUG:-"false"} == "true" ]]; then
  echo "Debug mode on"
  set -x
  PS4=' ::debug file=${BASH_SOURCE},line=${LINENO}::${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  export PS4
fi

function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

function process_multiline_variable() {
  local content="${*}"
  content="${content//'%'/'%25'}"
  content="${content//$'\n'/'%0A'}"
  content="${content//$'\r'/'%0D'}"
  content="${content//$'\t'/'%09'}"
  echo "${content}"
}

function trim() {
  local var="${*}"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  echo "${var}"
}

function trim_dash() {
  local var="${*}"
  var="${var#"${var%%[!-]*}"}"
  var="${var%"${var##*[!-]}"}"
  echo "${var}"
}

function safe_eb_env_name() {
  local var="${*}"
  var="${var//[+_. ]/-}"
  var="$(trim "${var}")"
  var="$(trim_dash "${var}")"
  echo "${var}"
}
function safe_eb_label_name() {
  local var="${*}"
  var="${var//[+]/-}"
  var="$(trim "${var}")"
  var="$(trim_dash "${var}")"
  echo "${var}"
}

function string_not_empty() {
  trimmedstring="$(trim "${*}")"
  test ${#trimmedstring} -gt 0
}

function pipe_errors_to_github_workflow() {
  while read -r data; do
    if string_not_empty "${data}"; then
      if echo "${data}" | grep -q -i "ERROR"; then
        if running_in_ci; then
          error_log "$(process_multiline_variable "${data}")"
        else
          printf "☠ %s\n" "$(process_multiline_variable "${data}")"
        fi
      else
        printf "ℹ %s\n" "$(process_multiline_variable "${data}")"
      fi
    fi
  done
}

function log_file_contents() {
  # echo "::warning file=app.js,line=1,col=5,endColumn=7::Missing semicolon"
  if [[ -f ${1} ]]; then
    if running_in_ci; then
      echo "::group::📄 ${1}"
      export GITHUB_LOG_TITLE="${DEPLOY_VERSION:-${GITHUB_ACTION:-${1:-}}}"
      export GITHUB_LOG_FILE="${1}"
      # shellcheck disable=SC2002
      cat "${1}" | pipe_errors_to_github_workflow
      unset ERROR_LOG_TITLE
      unset ERROR_LOG_FILE
      echo "::endgroup::"
    else
      debug_log "Log file contents: ${1}"
      printf "Log file contents: %s\n" "${1}"
      cat "${1}"
    fi
  fi
}

function pipe_errors_from_eb_logs_to_github_actions() {
  EB_ENV="${1:-${ENVIRONMENT_NAME}}"
  LOG_ZIP="${EB_ENV}.zip"
  if [[ ! -f ${LOG_ZIP} ]]; then
    echo "Retrieving logs from Elastic Beanstalk"
    EB_ENV="${1:-${ENVIRONMENT_NAME}}"
    if aws_run elasticbeanstalk request-environment-info --info-type bundle --environment-name "${EB_ENV}"; then
      if aws_run elasticbeanstalk retrieve-environment-info --info-type bundle --environment-name "${EB_ENV}"; then
        LOG_DOWNLOAD_URL="$(aws_run elasticbeanstalk retrieve-environment-info --info-type bundle --environment-name "${EB_ENV}" | jq -r ".EnvironmentInfo[0].Message")"
        if curl -sSlL -o "${LOG_ZIP}" "${LOG_DOWNLOAD_URL}"; then
          unzip -o "${LOG_ZIP}" -d .elasticbeanstalk/logs/ -x "*.gz"
          log_file_contents ".elasticbeanstalk/logs/var/log/eb-engine.log"
          log_file_contents ".elasticbeanstalk/logs/var/log/tomcat/wearsafe.log"
          log_file_contents ".elasticbeanstalk/logs/var/log/cloud-init-output.log"
          log_file_contents ".elasticbeanstalk/logs/var/log/tomcat/catalina.$(date +%Y-%m-%d).log"
        fi
      fi
    fi
  fi
}
function running_in_ci() {
  test -n "${CI:+x}"
}
function getLogType() {
  LOG_TYPES=(
    "error"
    "warning"
    "notice"
    "debug"
  )
  logtype="${1}"
  if echo "${LOG_TYPES[@]}" | grep -w -q -i "${logtype}"; then
    tr '[:upper:]' '[:lower:]' <<<"${logtype}"
  else
    echo ""
  fi
}
function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "${f}" "${@/#/${d}}"
  fi
}
function github_log() {
  logtype="$(getLogType "${1}")"
  shift
  MSG="$(trim "${*}")"
  MSG="$(process_multiline_variable "${MSG}")"
  if [[ ${#MSG} -gt 0 ]]; then
    if [[ ${#logtype} -gt 0 ]]; then
      LOG_STRING=("::${logtype} ")
      shift
      LOG_ARGS=()

      FILE="$(trim "${GITHUB_LOG_FILE:-${BASH_SOURCE[0]}}")"
      test "${#FILE}" -gt 0 && LOG_ARGS+=("file=${FILE}")
      test -n "${GITHUB_LOG_TITLE:-}" && LOG_ARGS+=("title=${GITHUB_LOG_TITLE}")
      if [[ ${#LOG_ARGS[@]} -gt 0 ]]; then
        ARGS="$(join_by , "${LOG_ARGS[@]}")"
        LOG_STRING+=("${ARGS}")
      fi
      LOG_STRING+=("::${MSG}")
      echo "${LOG_STRING[@]}"
    else
      printf "%s\n" "${MSG}"
    fi
  fi

}
function debug_log() {
  if [[ ${DEBUG:-false} == "true" ]]; then
    github_log debug "${*}"
  fi
}
function info_log() {
  github_log info "${*}"
}
function error_log() {
  github_log error "${*}"
}
function notice_log() {
  github_log notice "${*}"
}
function running_in_ci() {
  test -n "${CI:+x}"
}
function set_env() {
  if [[ $# -ne 2 ]]; then
    error_log "${0}: You need to provide two arguments. Provided args ${*}"
    return 1
  fi
  if running_in_ci; then
    echo "${1}=${2}" >>"${GITHUB_ENV}"
  fi
  export "${1}=${2}"
  debug_log "Environment Variable set: ${1}=${2}"
}
function set_output() {
  if [[ $# -ne 2 ]]; then
    error_log "${0}: You need to provide two arguments. Provided args ${*}"
    return 1
  fi
  if running_in_ci; then
    echo "::set-output name=${1}::${2}"
    debug_log "Output Variable set: ${1}=${2}"
  else
    debug_log "Not in CI, Output Variable not set: ${1}=${2}"
  fi

}

function add_to_path() {
  if [[ $# -ne 1 ]]; then
    error_log "${0}: You need to provide one arguments. Provided args ${*}"
    return 1
  fi
  export PATH="${1}:${PATH}"
  if running_in_ci; then
    echo "${1}" >>"${GITHUB_PATH}"
    debug_log "Path added: ${1}"
  else
    debug_log "Not in CI, Path added: ${1}"
  fi

}

function get_java_version() {
  if [[ -f .java-version ]]; then
    JAVA_VERSION="$(cat .java-version)"
  else
    JAVA_VERSION="11.0"
  fi
  echo "Java Version is: ${JAVA_VERSION}"
  set_output version "${JAVA_VERSION}"
}

function install_xmllint() {
  if ! command_exists xmllint; then
    sudo apt-get install -y -q libxml2-utils >/dev/null 2>&1
  fi
}

function pom_version() {
  if [[ $# -eq 0 ]]; then
    install_xmllint >/dev/null 2>&1
    xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml
  elif [[ $# -eq 1 ]]; then
    echo "Version set to $1"
    sed -i -e "1,/<version>.*<\/version>/ s/<version>.*<\/version>/<version>$1<\/version>/" pom.xml
    git add pom.xml
  else
    echo "Too many parameters"
  fi
}

function get_prerelease_suffix() {
  if [[ $# -eq 0 ]]; then
    echo "RC"
  else
    SUFFIX="$(echo "${1}" | sed -e 's;^refs/.*/;;g' -e 's;^.*/;;g')"
    export SUFFIX
  fi
}

function check_if_on_release_branch() {
  if [[ ${1//refs\/heads\//} == "${RELEASE_BRANCH//refs\/heads\//}" ]]; then
    set_output on true
    set_env ON_RELEASE_BRANCH true
    set_env BUMP_VERSION ${BUMP_VERSION:-patch}
  else
    set_output on false
    set_env ON_RELEASE_BRANCH false
    set_env BUMP_VERSION ${BUMP_VERSION:-build}
  fi
}
function getProperty() {
  PROP_KEY="$1"
  PROPERTY_FILE="$2"
  grep "${PROP_KEY}" "${PROPERTY_FILE}" | awk -F "=" '{print $2}' | sed "s/[\ '\"]//g"
}

function pom_buildnumber() {

  if [[ $# -eq 0 ]]; then
    install_xmllint
    xmllint --xpath '/*[local-name()="project"]/*[local-name()="properties"]/*[local-name()="buildnumber"]/text()' pom.xml
  elif [[ $# -eq 1 ]]; then
    echo "Build set to $1"
    sed -i -e "1,/<buildnumber>.*<\/buildnumber>/ s/<buildnumber>.*<\/buildnumber>/<buildnumber>$1<\/buildnumber>/" pom.xml
    git add pom.xml
  else
    echo "Too many parameters"
  fi
}
function prefix_sudo() {
  if command_exists sudo && ! sudo -v >/dev/null 2>&1; then
    echo sudo
  fi
}
function installer() {
  SUDO=$(prefix_sudo)
  if command_exists yum; then
    ${SUDO} yum "$@"
  elif command_exists apt-get; then
    ${SUDO} apt-get -q update && ${SUDO} apt-get "$@"
  elif command_exists brew; then
    brew "$@"
  else
    debug_log "Can't install: " "$@"
    exit 1
  fi
}
function install_app() {
  # Usage: install_app <app name> [second app] [third app]
  # Is App installed?
  INSTALL_LIST=()
  for cmd in "$@"; do
    if ! command_exists "${cmd}"; then
      debug_log "Installing ${cmd}"
      INSTALL_LIST+=("${cmd}")
    else
      debug_log "${cmd} installed already"
    fi
  done
  if [[ ${#INSTALL_LIST[@]} -gt 0 ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      installer install "${INSTALL_LIST[@]}"
    elif [[ "$(uname -s | cut -c1-5)" == "Linux" ]]; then
      installer install -y -q "${INSTALL_LIST[@]}"
    fi
  fi
}

function install_eb_cli() {
  debug_log "install_eb_cli: Install EB CLI"
  if ! command_exists python3; then
    install_app python3
  fi
  if [[ ${#INSTALL_LIST[@]} -gt 0 ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      installer install pkg-config libffi openssl
    elif [[ "$(uname -s | cut -c1-5)" == "Linux" ]]; then
      installer install -y -q build-essential libssl-dev libffi-dev cargo
    fi
  fi

  python -m pip install --upgrade wheel cryptography
  python -m pip install -r requirements.txt
}
function eb_run() {
  if ! command_exists eb; then
    install_eb_cli >/dev/null 2>&1
  fi
  if command_exists eb; then
    eb "${@}"
  else
    error_log "eb command not found"
    exit 1
  fi
}

function install_aws_cli() {
  curl -sSlL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" >/dev/null 2>&1
  (cd /tmp && unzip awscliv2.zip && sudo ./aws/install >/dev/null 2>&1)
}
function aws_run() {
  if ! command_exists aws; then
    install_aws_cli >/dev/null 2>&1 || (echo "Failed to install aws cli" && exit 1)
  fi
  aws "${@}"
}

function install_golang() {
  mkdir -p "${GOPATH}"
  chmod 766 /etc/go
  export GOPATH="${GOPATH:-/etc/go}"
  add_to_path "${GOPATH}"
  add_to_path "/usr/local/go/bin"
  export GO_VERSION="${GO_VERSION:-go1.15.3.linux-amd64.tar.gz}"
  if ! command_exists go; then
    debug_log "Installing GoLang"
    curl -LsSO "https://dl.google.com/go/${GO_VERSION}"
    tar -C /usr/local -xzf "${GO_VERSION}"
    cat <<EOF >/etc/profile.d/go.sh
export GOPATH=/etc/go
export PATH=\$PATH:\$GOPATH/bin:/usr/local/go/bin
EOF
    chmod +x /etc/profile.d/go.sh
    debug_log "Golang now installed"
  else
    debug_log "GoLang already Installed"
  fi
  # shellcheck disable=SC1091
  source /etc/profile.d/go.sh
}

function install_chamber() {
  # is chamber already installed?
  if ! command_exists chamber; then
    debug_log "Installing Chamber"
    go get github.com/segmentio/chamber
    debug_log "Chamber now installed"
  else
    debug_log "Chamber installed already"
  fi
}

function configure_bastion_ssh_tunnel() {
  if [ -z "${BASTION_HOST}" ] || [ -z "${BASTION_USER}" ] || [ -z "${BASTION_PRIVATE_KEY}" ]; then
    error_log "One or more essential bastion variables missing: BASTION_PRIVATE_KEY:'${BASTION_PRIVATE_KEY:0:10}' BASTION_HOST:'${BASTION_HOST}' BASTION_USER:'${BASTION_USER}'"
    exit 1
  fi
  mkdir -p "${HOME}/.ssh"
  if [ ! -f "${HOME}/.ssh/config" ]; then
    touch "${HOME}/.ssh/config"
  fi
  if ! grep -q "remotehost-proxy" "${HOME}/.ssh/config"; then
    cat <<EOF >>"${HOME}/.ssh/config"
Host remotehost-proxy
    HostName ${BASTION_HOST}
    User ${BASTION_USER}
    IdentityFile ${HOME}/.ssh/bastion.pem
    ControlPath ${HOME}/.ssh/remotehost-proxy.ctl
    ForwardAgent yes
    TCPKeepAlive yes
    ConnectTimeout 5
    ServerAliveInterval 60
    ServerAliveCountMax 30

EOF
  fi
  # ControlPath ${HOME}/.ssh/remotehost-proxy.ctl
  touch "${HOME}/.ssh/known_hosts"
  rm -f "${HOME}/.ssh/bastion.pem"
  echo "${BASTION_PRIVATE_KEY}" | base64 -d >"${HOME}/.ssh/bastion.pem"
  chmod 700 "${HOME}/.ssh" || true
  chmod 600 "${HOME}/.ssh/bastion.pem" || true
  if ! grep -q "${BASTION_HOST}" "${HOME}/.ssh/known_hosts"; then
    ssh-keyscan -T 15 -t rsa "${BASTION_HOST}" >>"${HOME}/.ssh/known_hosts" || true
  fi

}
function check_ssh_tunnel() {
  ssh -O check remotehost-proxy >/dev/null 2>&1
}
function open_bastion_ssh_tunnel() {
  if ! check_ssh_tunnel; then
    ssh -4 -f -T -M -L"${BINDHOST:-127.0.0.1}:${JDBC_LOCAL_PORT:-${JDBC_PORT:-3306}}:${JDBC_HOST}:${JDBC_PORT:-3306}" -N remotehost-proxy && echo "SSH tunnel connected"
  else
    echo "SSH tunnel already connected"
  fi
}
function close_bastion_ssh_tunnel() {
  if [[ -f "${HOME}/.ssh/remotehost-proxy.ctl" ]]; then
    ssh -T -O "exit" remotehost-proxy
  fi
}

function install_dependencies() {
  install_app zip unzip curl git jq wget
  install_golang
  install_chamber
}

function version_available() {
  VERSION_AVAILABLE="$(aws_run elasticbeanstalk describe-application-versions \
    --application-name "${APPLICATION_NAME}" \
    --version-labels "${1}" \
    --query "ApplicationVersions[0].VersionLabel" \
    --output text)"
  if [[ ${VERSION_AVAILABLE} == "${1}" ]]; then
    return 0
  else
    return 1
  fi
}

function create_application_version() {
  APPLICATION_VERSION_LABEL="${1}"
  DESCRIPTION="${2}"

  if ! version_available "${APPLICATION_VERSION_LABEL}"; then
    debug_log "Creating application version ${APPLICATION_VERSION_LABEL}"
    eb_run appversion -a "${APPLICATION_NAME}" \
      --label "${APPLICATION_VERSION_LABEL}" \
      --create \
      --process \
      --staged \
      -m "${DESCRIPTION:-${APPLICATION_VERSION_LABEL}}"
  fi

}

function cname_available() {
  aws_run elasticbeanstalk check-dns-availability \
    --cname-prefix "${APPLICATION_CNAME_PREFIX:-${APPLICATION_NAME}}-${1}${APPLICATION_CNAME_SUFFIX:-}" \
    --output text \
    --query "[Available]" |
    tr '[:upper:]' '[:lower:]'
}
function passive_cname_prefix() {
  echo "${APPLICATION_CNAME_PREFIX:-${APPLICATION_NAME}}-passive${APPLICATION_CNAME_SUFFIX:-}"
}
function wait_for_passive_cname() {
  while [[ "$(cname_available "passive")" != "true" ]]; do
    sleep 1
  done
}
function remove_passive() {
  ENV_NAME_TO_REMOVE="$(environment_name_by_cname passive)"
  timeout 60 pipe_errors_from_eb_logs_to_github_actions "${ENV_NAME_TO_REMOVE}" || true
  eb_run terminate --nohang --force "${ENV_NAME_TO_REMOVE}"
  event_logs_background "${ENV_NAME_TO_REMOVE}" &
  notice_log "Passive Environment '${ENV_NAME_TO_REMOVE}' termination signal sent - waiting for CNAME $(passive_cname_prefix) to be released"
  if [[ $1 == "hang" ]]; then
    timeout 180 wait_for_passive_cname &&
      notice_log "Passive Environment '${ENV_NAME_TO_REMOVE}' has released the CNAME $(passive_cname_prefix)"
  fi

}

function environment_name_by_cname() {
  CNAME="${APPLICATION_CNAME_PREFIX:-${APPLICATION_NAME}}-${1:-passive}${APPLICATION_CNAME_SUFFIX:-}.${REGION:-us-east-1}.elasticbeanstalk.com"
  aws_run elasticbeanstalk describe-environments \
    --application "${APPLICATION_NAME}" \
    --no-paginate \
    --output text \
    --query "Environments[?CNAME==\`${CNAME}\` && Status!=\`Terminated\`].[EnvironmentName]"
}

function environment_exists() {
  ENV_LIST_LENGTH="$(aws_run elasticbeanstalk describe-environments --application "${APPLICATION_NAME}" --environment-name "${ENVIRONMENT_NAME}" --query 'Environments[?Status!=`Terminated`]' --output json | jq -r 'length')"
  test "${ENV_LIST_LENGTH:-0}" -eq 1
}

function count_environments() {
  aws_run elasticbeanstalk describe-environments --application "${APPLICATION_NAME}" --output json --query 'Environments[?Status!=`Terminated`]' | jq -r 'length'
}

function event_logs_background() {
  EVENT_LOG_PATH=/tmp/eb_events.log
  TARGET_ENV="${1:-${ENVIRONMENT_NAME}}"
  rm -rf "${EVENT_LOG_PATH}"
  touch "${EVENT_LOG_PATH}"
  while ! eb_run events "${TARGET_ENV}" >/dev/null 2>&1; do
    sleep 3
  done
  eb_run events --follow "${TARGET_ENV}" | tee -a "${EVENT_LOG_PATH}" | while read -r line; do
    if echo "${line}" | grep -q -i -e "(ERROR|Terminating)"; then
      pipe_errors_from_eb_logs_to_github_actions "${TARGET_ENV}"
    fi
  done &
  tail -f "${EVENT_LOG_PATH}" &
}

function create_environment() {
  info_log "Creating environment ${ENVIRONMENT_NAME} within application ${APPLICATION_NAME}"
  if [[ -z ${DEPLOY_VERSION} ]]; then
    eb_run create \
      --cfg "${ENVIRONMENT_CFG}" \
      --cname "${CNAME_PREFIX}" \
      --timeout "${TIMEOUT_IN_MINUTES}" \
      "${ENVIRONMENT_NAME}" &
    PID="$!"
  elif version_available "${DEPLOY_VERSION}"; then
    eb_run create \
      --cfg "${ENVIRONMENT_CFG}" \
      --cname "${CNAME_PREFIX}" \
      --timeout "${TIMEOUT_IN_MINUTES}" \
      --version "${DEPLOY_VERSION}" \
      "${ENVIRONMENT_NAME}" &
    PID="$!"
  else
    error_log "The version label to be deployed ${DEPLOY_VERSION} is unavailable"
    exit 1
  fi
  event_logs_background "${ENVIRONMENT_NAME}" &
  wait "${PID}"
  pipe_errors_from_eb_logs_to_github_actions "${ENVIRONMENT_NAME}"

}
function get_list_of_docker_tags() {
  DOCKER_IMAGE_NAME="$("${DIR}"/get-app-name.sh)"
  aws ecr list-images --repository-name "${DOCKER_IMAGE_NAME}" --filter tagStatus=TAGGED --region us-east-1
}
function deploy_asset() {
  if [[ -z ${DEPLOY_VERSION} ]]; then
    error_log "The env variable DEPLOY_VERSION is required"
    exit 1
    # eb_run deploy \
    #     --process \
    #     --timeout "${TIMEOUT_IN_MINUTES}" \
    #     "${ENVIRONMENT_NAME}"
  else
    eb_run deploy \
      --version "${DEPLOY_VERSION}" \
      --staged \
      --label "${DEPLOY_VERSION}" \
      --timeout "${TIMEOUT_IN_MINUTES:-20}" \
      "${ENVIRONMENT_NAME}"
  fi
}

function eb_init() {
  info_log "eb_init: Init EB CLI"
  if [[ -z ${EB_PLATFORM} ]]; then
    error_log "eb_init: function requires an EB_PLATFORM environment variable to exist"
    return 1
  fi
  EB_ARGS=("--platform=${EB_PLATFORM}")
  [[ -n ${REGION} ]] && EB_ARGS+=("--region=${REGION}")
  [[ -n ${EC2_KEYNAME} ]] && EB_ARGS+=("--keyname=${EC2_KEYNAME}")

  eb_run init "${EB_ARGS[@]}" "${APPLICATION_NAME}"

}

function eb_load_config() {
  info_log "eb_load_config: Load Config from file to EB: ${ENVIRONMENT_CFG}"
  if [[ -z ${ENVIRONMENT_CFG} ]]; then
    error_log "eb_load_config: function requires an ENVIRONMENT_CFG environment variable to exist"
    return 1
  fi
  eb_run config put "${ENVIRONMENT_CFG}"

}

function set_build_framework_output() {
  if [[ -f "build.gradle" ]]; then
    set_output is gradle
  elif [[ -f "pom.xml" ]]; then
    set_output is maven
  fi
}

function set_build_framework_env() {
  if [[ -f "build.gradle" ]]; then
    set_env FRAMEWORK gradle
  elif [[ -f "pom.xml" ]]; then
    set_env FRAMEWORK maven
  fi
}

function check_if_tag_created() {
  git fetch --depth=1 origin "+refs/tags/*:refs/tags/*" >/dev/null 2>&1 &&
    git describe --exact-match >/dev/null 2>&1
}
function get_tag_name() {
  git describe --exact-match
}
function set_tag_as_output_if_available() {
  if check_if_tag_created; then
    set_env GITHUB_TAG "$(get_tag_name)"
    set_output tag "${GITHUB_TAG}"
  else
    set_output tag "unknown"
  fi
}

function parse_yaml() {
  local prefix=$2
  local s
  local w
  local fs
  s='[[:space:]]*'
  w='[a-zA-Z0-9_]*'
  fs="$(echo @ | tr @ '\034')"
  #shellcheck disable=SC1087,SC2250
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
        }
    }' | sed 's/_=/+=/g'
}

function run_flyway_migration() {
  docker context use "default"
  if [[ -z "$(docker network list -q -f 'name=api-backend')" ]]; then
    docker network create --driver bridge api-backend
    NETWORK_CREATED=true
  fi
  if docker compose -p flyway --project-directory "${GITHUB_WORKSPACE:-./}" -f "${FLYWAY_DOCKER_COMPOSE_FILE}" run --rm flyway; then
    ERRORED=false
  fi
  if [[ "${NETWORK_CREATED}" == true ]]; then
    docker network rm api-backend || true
  fi
  if [[ "${ERRORED}" != false ]]; then
    error_log "Flyway migration failed"
    return 1
  fi
}

function create_mysql_tunnel() {
  rm -f ~/.ssh/remotehost-proxy.ctl

  # Set up the configuration for ssh tunneling to the bastion server
  configure_bastion_ssh_tunnel

  # Start the ssh tunnel for MySQL
  set_env BINDHOST "0.0.0.0"
  set_env JDBC_LOCAL_PORT "33307"
  open_bastion_ssh_tunnel
}

function setup_local_mysql_route_variables() {
  # Get the local hosts IP
  if [ -f '/sbin/ip' ]; then
    # DOCKERHOST="$(/sbin/ip route | awk '/default/ { print  $3}')"
    DOCKERHOST="$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)"
    echo "Using the docker hosts ethernet IP ${DOCKERHOST} for accessing mysql"

  else
    DOCKERHOST=127.0.0.1
    echo "Using the docker hosts local IP ${DOCKERHOST} for accessing mysql"
  fi
  set_env DOCKERHOST "127.0.0.1"

  # Set the mysql host to the docker host to use the tunnel
  set_env JDBC_HOST "${DOCKERHOST}"
  set_env JDBC_PORT "${JDBC_LOCAL_PORT}"
}

export BASH_FUNCTIONS_LOADED=1
