#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

printf '%b\n' ":: Reading release config...."
source $CUR_DIR/release.sh

readonly RETAG_REPOSITORY=$1
readonly PUSH_VERSION=$JIRA_VERSION
readonly PUSH_SERVICE_DESK_VERSION=$JIRA_SERVICE_DESK_VERSION

function retagImage() {
  local tagname=$1
  local repository=$2
  docker tag teamatldocker/confluence:$tagname $repository/confluence:$tagname
}

retagImage latest $PUSH_REPOSITORY
retagImage $PUSH_VERSION $PUSH_REPOSITORY
