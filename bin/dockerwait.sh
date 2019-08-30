#!/bin/bash

set -o errexit

function dockerWaitInit {
  CURRENT_DOCKER_WAIT_HOST=$DOCKER_WAIT_HOST
  CURRENT_DOCKER_WAIT_PORT=$DOCKER_WAIT_PORT
  CURRENT_DOCKER_WAIT_TIMEOUT=${DOCKER_WAIT_TIMEOUT:-60}
  CURRENT_DOCKER_WAIT_INTERVAL=${DOCKER_WAIT_INTERVAL:-5}
}

function dockerPoll {
  local totalTime=0
  while ! nc $CURRENT_DOCKER_WAIT_HOST $CURRENT_DOCKER_WAIT_PORT </dev/null;
  do
    echo "Waiting for $CURRENT_DOCKER_WAIT_HOST:$CURRENT_DOCKER_WAIT_PORT ..."
    sleep $CURRENT_DOCKER_WAIT_INTERVAL;
    totalTime=$(($totalTime+$CURRENT_DOCKER_WAIT_INTERVAL))
    if [ "$totalTime" -ge "$CURRENT_DOCKER_WAIT_TIMEOUT" ]
    then
      echo "Timeout ..."; false;
    fi
  done
}

function dockerWait {
  if [ -n "${DOCKER_WAIT_HOST}" ] && [ -n "${DOCKER_WAIT_PORT}" ]; then
    dockerPoll
  fi
}

dockerWaitInit
dockerWait
