#!/usr/bin/env bash
set -e
function xtrace() {
  # Print the line as if xtrace was turned on, using sed to filter out
  # the extra colon character and the following "set +x" line.
  (
    set -x
    # Colon is a no-op in bash, so nothing will execute.
    "$@"
    set +x
  ) 2>&1 | sed -e 's/^[+]:/+/g' -e '/^[+]*set +x$/d' 1>&2
  # Execute the original line unmolested
  # "$@"
}
function __ps4_ret() {
  # Don't pollute the return value in case we use it for something else
  local _r=$?
  if ((_r == 0)); then
    printf '+'
  elif ((_r >= 1)); then
    printf "%s::error file=%s,line=%d,title=%s::" $'\b' "${BASH_SOURCE[1]}" "${LINENO}" "${FUNCNAME[1]:+${FUNCNAME[1]}()}"
  fi
  return "${_r}"
}
export -f __ps4_ret
if [[ "${DEBUG:-"false"}" = "true" ]]; then
  echo "Debug mode on"
  set -x
  export PS4='$(__ps4_ret)'
fi
#shellcheck disable=SC2183
function quiet_trace() {
  if [[ -o xtrace ]] && [[ -n "${1}" ]]; then
    if [[ "$(type -t "${1}" 2>/dev/null)" == 'function' ]]; then
      # It is a function
      # Check if it has the keyword "## [QUIET_TRACING]"
      if [[ -n ${QUIET_TRACING} ]]; then
        TRACE_FUNC_NAME="tracing_enable_${1}"
        # Mixed tabs and spaces below on purpose for the -EOF comment
        eval "$(printf 'function %s() { echo "calling_unset";  precmd_functions=( "${precmd_functions[@]/%s}" );  unset "%s"; set -x; };' $(seq -f "%g\b${TRACE_FUNC_NAME}" -s " " 1 3))"
        declare -f "${TRACE_FUNC_NAME}" || echo "Failed to declare ${TRACE_FUNC_NAME}"
        export -f "${TRACE_FUNC_NAME?}"
        precmd_functions+=("${TRACE_FUNC_NAME}")
        set +x
      else
        echo "Quiet tracing not enabled for ${1}"
      fi
    fi
  fi
}

# trap_fn_debug_quiet() (
#   [[ -n ${QUIET_TRACING} ]] && [[ ${BASH_COMMAND} != "unset QUIET_TRACING" ]] &&
#     unset QUIET_TRACING && set -x
#   return 0 # do not block execution in extdebug mode
# )
# trap trap_fn_debug_quiet DEBUG

# trap_fn() {
#   [[ -n ${DEBUG} ]] && [[ ${BASH_COMMAND} != "unset DEBUG" ]] &&
#     printf "[%s:%s] %s\n" "${BASH_SOURCE[0]}" "${LINENO}" "${BASH_COMMAND}"
#   return 0 # do not block execution in extdebug mode
# }
# trap trap_fn DEBUG

# DEBUG=1
# # ...do something you want traced...
# unset DEBUG

# if [[ "${preexec_functions[*]}" =~ "quiet_trace" ]]; then
#   preexec_functions=("${preexec_functions[@]/quiet_trace/}")
# fi
# preexec_functions+=(quiet_trace)
