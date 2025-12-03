VERSION_FILE    = 'package.json'
PROJECT_NAME    := $(shell if [ -e ${VERSION_FILE} ] ; then jq -r .name    ${VERSION_FILE} ; else echo "NO FILE: ${VERSION_FILE}" ; fi)
PROJECT_VERSION := $(shell if [ -e ${VERSION_FILE} ] ; then jq -r .version ${VERSION_FILE} ; else echo "NO FILE: ${VERSION_FILE}" ; fi)

NEW_PROJECT_VERSION = "$(shell echo "${PROJECT_VERSION}" | perl -pe 's/([0-9]+).([0-9]+).([0-9]+)/"$$1.".($$2+1).".$$3"/e')"

default: help

.PHONY: package-info
package-info: ## display project info
	@echo "ENV=[${ENV}]"
	@echo "ENV_CONFIG=[${ENV_CONFIG}]"
	@echo "PROJECT_NAME=[${PROJECT_NAME}]"
	@echo "PROJECT_VERSION=[${PROJECT_VERSION}]"

.PHONY: get-name
get-name: ## display project name
	@echo ${PROJECT_NAME}

.PHONY: get-version
get-version: ## display project version
	@echo ${PROJECT_VERSION}

.PHONY: config
config: ${ENV_CONFIG} ## copy .env config from the 'environments' folder
	ls -la ${ENV_CONFIG}
	cp ${ENV_CONFIG} .env
	ls -la .env

.env:
	make config

.PHONY: increment-version
increment-version: ## increment version in package.json
	jq '.version = ${NEW_PROJECT_VERSION}' ${VERSION_FILE} | sponge ${VERSION_FILE}



.PHONY: commit-version
commit-version: ## commit version in package.json
	git add ${VERSION_FILE}
	git commit --no-verify --allow-empty -m "[skip ci] Update Version"
	git push origin main
