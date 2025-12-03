#!/bin/bash
set -ex

ARTIFACTFILE="${ARTIFACTFILE:=testing}.zip"


echo "Build: ${ARTIFACTFILE}"

zip -r ${ARTIFACTFILE} \
  .ebextensions \
  .platform \
  Dockerrun.aws.json \
  docker-compose.yml

# HACK: for compatabilty with current pipeline
echo "Moving: ${ARTIFACTFILE} to target/${ARTIFACTFILE}"
mkdir -p target
mv ${ARTIFACTFILE} target/${ARTIFACTFILE}
