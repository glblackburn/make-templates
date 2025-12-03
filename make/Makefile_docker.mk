# Set PROJECT_NAME, ENVIRONMENT, PROJECT_VERSION, BUILD_NUMBER, DOCKER_PORT, and DOCKER_HOST in project

# DO NOT USE ':=' !!
#'=' allows the DOCKER_ variables to be set after the template is imported.
DOCKER_NAME  = ${DOCKER_HOST}/${PROJECT_NAME}

DOCKER_ENVIRONMENT  = $(if $(ENVIRONMENT),$(ENVIRONMENT),latest)
DOCKER_VERSION      = $(if $(PROJECT_VERSION),$(PROJECT_VERSION),${GIT_SHA})
DOCKER_BUILD_NUMBER = $(if $(BUILD_NUMBER),$(BUILD_NUMBER),${GIT_SHA})

DOCKER_LATEST_TAG  = ${DOCKER_NAME}:${DOCKER_ENVIRONMENT}
DOCKER_VERSION_TAG = ${DOCKER_NAME}:${DOCKER_ENVIRONMENT}-${DOCKER_VERSION}-${DOCKER_BUILD_NUMBER}

# TAG            = "${VERSION}-${ENVIRONMENT}-${BUILD_NUMBER}"
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${TAG} \
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${ENVIRONMENT} \

DOCKER_PORT        := $(if $(DOCKER_PORT),$(DOCKER_PORT),80)
DOCKER_CONTAINER_NAME = $(shell echo "${PROJECT_NAME}" | sed "s/\//_/g")
DOCKER_URL         = http://localhost:${DOCKER_PORT}/

default: help

.PHONY: docker-info
docker-info: ## show docker make variables
	@echo "PROJECT_NAME           =[${PROJECT_NAME}]"
	@echo "ENVIRONMENT            =[${ENVIRONMENT}]"
	@echo "GIT_SHA                =[${GIT_SHA}]"
	@echo "DOCKER_HOST            =[${DOCKER_HOST}]"
	@echo "DOCKER_NAME            =[${DOCKER_NAME}]"
	@echo "DOCKER_PORT            =[${DOCKER_PORT}]"
	@echo "DOCKER_URL             =[${DOCKER_URL}]"
	@echo "DOCKER_CONTAINER_NAME  =[${DOCKER_CONTAINER_NAME}]"
	@echo "DOCKER_LATEST_TAG      =[${DOCKER_LATEST_TAG}]"
	@echo "DOCKER_VERSION_TAG     =[${DOCKER_VERSION_TAG}]"


### Parts of the pipeline code to trace the values
#                                sh """#!/bin/bash
#                                    docker build --ssh default \
#                                        --build-arg BUILDKIT_INLINE_CACHE=1 \
#                                        --build-arg GIT_SHA=${GIT_SHA} \
#                                        --build-arg ENVIRONMENT=${ENVIRONMENT} \
#                                        --build-arg DEPLOY_COLOR=${DEPLOY_COLOR} \
#                                        --cache-from ${DOCKER_HOST}/${PROJECT_NAME}:${ENVIRONMENT} \
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${TAG} \
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${ENVIRONMENT} \
#                                        .
#                                """
#
#                    PROJECT_NAME   = "${JOB_NAME}".split("/")[0]
#                    TAG            = "${VERSION}-${ENVIRONMENT}-${BUILD_NUMBER}"
#                    VERSION        = sh(script: 'make get-version', returnStdout: true).toString().trim()
#
#                    ENV=${ENVIRONMENT}/${AWS_REGION} make create-pr-configs
#Makefile_terraform.mk:ENVIRONMENT := $(shell echo "${ENV}" | sed "s/\/.*$$//")
#                    switch (BRANCH_NAME) {
#                    case 'dev':
#                        ENVIRONMENT    = 'dev'
#                    case 'qa':
#                        ENVIRONMENT    = 'qa'
#                    case 'staging':
#                        ENVIRONMENT    = 'staging'
#                    case ~/master|main/:
#                        ENVIRONMENT    = 'prod'
#                    default:
#                        ENVIRONMENT    = BRANCH_NAME
#                    }

.PHONY: docker-build
docker-build: Dockerfile ## build docker image
	@echo "check for docker-deps target for optional setup"
	(make docker-deps || echo "make docker-deps: Exit code: $$?")
	docker build --ssh default -t ${DOCKER_LATEST_TAG} -t ${DOCKER_VERSION_TAG} .

#                                    docker build 
#                                        --build-arg BUILDKIT_INLINE_CACHE=1 \
#                                        --build-arg GIT_SHA=${GIT_SHA} \
#                                        --build-arg ENVIRONMENT=${ENVIRONMENT} \
#                                        --build-arg DEPLOY_COLOR=${DEPLOY_COLOR} \
#                                        --cache-from ${DOCKER_HOST}/${PROJECT_NAME}:${ENVIRONMENT} \
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${TAG} \
#                                        -t ${DOCKER_HOST}/${PROJECT_NAME}:${ENVIRONMENT} \
#                                        .
	make docker-info

.PHONY: docker-run
docker-run:  ## run docker image and open in browser
	@echo "Starting app on ${DOCKER_URL}"
	( sleep 3 ;  open ${DOCKER_URL} ) &
	make docker-info
	make docker-run-forground

.PHONY: docker-run-background
docker-run-background: ## run app in the background
	docker run -p ${DOCKER_PORT}:${DOCKER_PORT} --rm --name ${DOCKER_CONTAINER_NAME} -d ${DOCKER_VERSION_TAG}

.PHONY: docker-run-forground
docker-run-forground: ## run app in the forground
	docker run -p ${DOCKER_PORT}:${DOCKER_PORT} --rm --name ${DOCKER_CONTAINER_NAME} -it ${DOCKER_VERSION_TAG}

.PHONY: docker-push
docker-push: ## push docker image to nexus
	docker push --all-tags ${DOCKER_NAME}
	make docker-info
