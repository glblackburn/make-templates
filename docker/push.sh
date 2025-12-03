#!/bin/bash
set -e

docker push ${DOCKER_REGISTRY}/${PROJECT_NAME}:${PROJECT_VERSION_TAG}
