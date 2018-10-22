#!/bin/bash -x

set -o errexit    # abort script at first error

function testImage() {
  local tagname=$1
  local iteration=0
  docker run -d --network confluence_dockertestnet --name=confluence.$tagname blacklabelops/confluence:$tagname
  while ! docker run --rm --network confluence_dockertestnet blacklabelops/jenkins-swarm curl http://confluence.$tagname:8080
  do
      { echo "Exit status of curl (${iteration}): $?"
        echo "Retrying ..."
      } 1>&2
      if [ "$iteration" = '30' ]; then
        exit 1
      else
        ((iteration=iteration+1))
      fi
      sleep 10
  done
  docker stop confluence.$tagname
}

testImage $1
