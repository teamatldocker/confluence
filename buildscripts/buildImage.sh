#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local version=$1
  local tagname=$2
  local language=$3
  local country=$4
  docker build --no-cache -t teamatldocker/confluence:$tagname --build-arg CONFLUENCE_VERSION=$version --build-arg LANG_LANGUAGE=$language --build-arg LANG_COUNTRY=$country --build-arg BUILD_DATE=$(date +"%d/%m/%y-%T%z") -f Dockerfile .
}

buildImage $1 $2 $3 $4
