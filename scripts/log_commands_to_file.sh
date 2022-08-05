#!/bin/bash
# set -e
# set -o pipefail
# shellcheck disable=SC2064
# test if fd 1 (STDOUT) is NOT associated with a terminal
if [[ ! -t 1 ]]; then

  # location of named pipe
  named_pipe=/tmp/$$.tmp

  # remove pipe on the exit signal
  trap "rm -f ${named_pipe}" EXIT

  # create named pipe
  mknod "${named_pipe}" p

  # start logger process in background with STDIN coming from named pipe
  # also tell logger to append the script name to the syslog messages
  # so we know where they came from
  logger <"${named_pipe}" -t "$0" &

  # or maybe you wanted a log file and output to STDOUT
  # tee <"${named_pipe}" /tmp/outfile &

  # redirect stderr and stdout to named_pipe
  exec 1>"${named_pipe}" 2>&1

fi

"$@"
