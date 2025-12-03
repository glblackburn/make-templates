#!/bin/bash
set -e

cat<<EOF
================================================================================
build.sh: debug info
DOCKER_BASE_IMAGE=[${DOCKER_BASE_IMAGE}]
PROJECT_NAME=[${PROJECT_NAME}]
PROJECT_VERSION=[${PROJECT_VERSION}]
PROJECT_ENVIRONMENT=[${PROJECT_ENVIRONMENT}]
DOCKER_REGISTRY=[${DOCKER_REGISTRY}]
PROJECT_VERSION_TAG=[${PROJECT_VERSION_TAG}]
ARTIFACTFILE=[${ARTIFACTFILE}]
EOF

PROJECT_JAR="target/${PROJECT_NAME}-${PROJECT_VERSION}.jar"
cat<<EOF
PROJECT_JAR=[${PROJECT_JAR}]
================================================================================
EOF

# Mimic jenkins pipeline for local testing
if [ ! -f "target/${PROJECT_NAME}-${PROJECT_VERSION}.jar" ]; then
  echo 'Building local jar'

  dockerBuildImage="$(.dockertmp/bin/yq eval '.docker_build_images' .devops/jenkins.yaml)"
  if [ "$dockerBuildImage" = 'null' ]; then
    dockerBuildImage='maven:3.8-openjdk-8'
  fi

  docker run -it --rm -v $HOME/.m2:/root/.m2 -v $PWD:/src -w /src $dockerBuildImage mvn clean package
  docker run -it --rm -v $PWD:/src -w /src busybox chown -R 1000:1000 target
fi

if [ "${DOCKER_BASE_IMAGE}" == "null" ]; then
  docker build \
    --build-arg PROJECT_NAME=${PROJECT_NAME} \
    --build-arg PROJECT_VERSION=${PROJECT_VERSION} \
    --build-arg PROJECT_ENVIRONMENT=${PROJECT_ENVIRONMENT} \
    -t ${DOCKER_REGISTRY}/${PROJECT_NAME}:${PROJECT_VERSION_TAG} .
else
  docker build \
    --build-arg DOCKER_BASE_IMAGE=${DOCKER_BASE_IMAGE} \
    --build-arg PROJECT_NAME=${PROJECT_NAME} \
    --build-arg PROJECT_VERSION=${PROJECT_VERSION} \
    --build-arg PROJECT_ENVIRONMENT=${PROJECT_ENVIRONMENT} \
    -t ${DOCKER_REGISTRY}/${PROJECT_NAME}:${PROJECT_VERSION_TAG} .
fi
