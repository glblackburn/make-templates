# Standard terraform options
TF_OPTIONS        = -input=false -no-color

TF_BACKEND_CONFIG = $(ENV_PREFIX).backend.config
TF_VARS           = $(ENV_PREFIX).tfvars

TF_OUTPUT_APPLY   = $(OUT_PREFIX)_apply.txt
TF_OUTPUT_DESTROY = $(OUT_PREFIX)_destroy.txt
TF_OUTPUT_INIT    = $(OUT_PREFIX)_init.txt
TF_OUTPUT_JSON    = $(OUT_PREFIX)_output.json
TF_OUTPUT_PLAN    = $(OUT_PREFIX)_plan.txt
TF_PULLED_STATE   = ${OUT_PREFIX}_pulled.tfstate
TF_VERSION        := $(shell if [ -e terraform.tf ] ; then cat terraform.tf | grep required_version | sed 's/^ *required_version *= * "\(.*\)"/\1/' ; else echo "NO FILE: terraform.tf" ; fi)

ENV         := $(if $(ENV),$(ENV),$(ENV_DEFAULT))

READ_PROP := $(shell if [ -e ./.make/make/read-property.sh ] ; then echo "./.make/make/read-property.sh" ; else echo "./read-property.sh" ; fi)

AWS_PROFILE = $(shell ${READ_PROP} '${TF_BACKEND_CONFIG}' 'profile')
REGION = $(shell ${READ_PROP} '${TF_BACKEND_CONFIG}' 'region')
BUCKET = $(shell ${READ_PROP} '${TF_BACKEND_CONFIG}' 'bucket')
KEY    = $(shell ${READ_PROP} '${TF_BACKEND_CONFIG}' 'key')

default: help

.PHONY: setup
setup: brew tfenv terraform ## setup tool dependancies

.PHONY: terraform-info
terraform-info: ## show variables that are setup for targets
	@echo "ENV_DEFULT        =[${ENV_DEFAULT}]"
	@echo "ENV               =[${ENV}]"
	@echo "ENV_PATH          =[${ENV_PATH}]"
	@echo "ENV_PREFIX        =[${ENV_PREFIX}]"
	@echo "TF_BACKEND_CONFIG =[${TF_BACKEND_CONFIG}]"
	@echo "TF_VARS           =[${TF_VARS}]"
	@echo "TF_VERSION        =[${TF_VERSION}]"
	@echo "REGION            =[${REGION}]"
	@echo "BUCKET            =[${BUCKET}]"
	@echo "KEY               =[${KEY}]"
	@echo "READ_PROP         =[${READ_PROP}]"

.PHONY: show-envs
show-envs: ## show available environments
	@find ${ENV_PATH} -type f -name "*.backend.config" | sed "s#${ENV_PATH}/\(.*\).backend.config#ENV=\1#" | sed "s#$(ENV_DEFAULT)#$(ENV_DEFAULT) \[default\]#"
#ENV_LIVE check needs more thought for being generic.  this was pretty specific to the jenkins/nexus setup.
#	@find ${ENV_PATH} -type f -name "*.backend.config" | sed "s#${ENV_PATH}/\(.*\)/us-east-1.backend.config#ENV=\1#" | sed "s#$(ENV_DEFAULT)#$(ENV_DEFAULT) \[default\]#" | sed "s#$(ENV_LIVE)#$(ENV_LIVE) \[live\]#"

.terraform:
	make init

.PHONY: init
init: tfenv terraform ${TF_BACKEND_CONFIG}
	@echo "TF_BACKEND_CONFIG =[${TF_BACKEND_CONFIG}]"
	@echo "TF_OUTPUT_INIT    =[${TF_OUTPUT_INIT}]"
	@echo "TF_VERSION        =[${TF_VERSION}]"
	mkdir -p $$(dirname ${TF_OUTPUT_INIT})
	rm -rf .terraform
	tfenv use ${TF_VERSION} || { tfenv install ${TF_VERSION} && tfenv use ${TF_VERSION} ; }
	terraform init -backend-config ${TF_BACKEND_CONFIG} -no-color 2>&1 | tee ${TF_OUTPUT_INIT}
	# for initial creation of central bucket/dynamodb table
	#terraform init -no-color 2>&1 | tee ${TF_OUTPUT_INIT}

.PHONY: init-migrate-state
init-migrate-state: tfenv terraform ${TF_BACKEND_CONFIG}
	@echo "TF_BACKEND_CONFIG =[${TF_BACKEND_CONFIG}]"
	@echo "TF_OUTPUT_INIT    =[${TF_OUTPUT_INIT}]"
	@echo "TF_VERSION        =[${TF_VERSION}]"
	mkdir -p $$(dirname ${TF_OUTPUT_INIT})
	tfenv use ${TF_VERSION} || { tfenv install ${TF_VERSION} && tfenv use ${TF_VERSION} ; }
	terraform init --migrate-state -backend-config ${TF_BACKEND_CONFIG} -no-color 2>&1 | tee ${TF_OUTPUT_INIT}

.PHONY: init-upgrade
init-upgrade: tfenv terraform ${TF_BACKEND_CONFIG}
	mkdir -p $$(dirname ${TF_OUTPUT_INIT})
	rm -rf .terraform
	tfenv use ${TF_VERSION}
	terraform init -upgrade -backend-config ${TF_BACKEND_CONFIG} -no-color 2>&1 | tee ${TF_OUTPUT_INIT}

.PHONY: plan
plan: terraform init ${TF_VARS} ## run terraform plan
	terraform plan    -var-file="${TF_VARS}" ${TF_OPTIONS} 2>&1 | tee ${TF_OUTPUT_PLAN}

.PHONY: apply
apply: terraform init ${TF_VARS} ## run terraform apply
	terraform apply   -var-file="${TF_VARS}" ${TF_OPTIONS} --auto-approve 2>&1 | tee ${TF_OUTPUT_APPLY}
	make output

.PHONY: output
output: terraform .terraform ${TF_VARS} ## run terraform output (WARNING: can point to wrong ENV if init not run)
	terraform output -json > ${TF_OUTPUT_JSON}

.PHONY: destroy
destroy: not-live terraform init ${TF_VARS} ## run terraform destroy
	terraform destroy -var-file="${TF_VARS}" ${TF_OPTIONS} --auto-approve 2>&1 | tee ${TF_OUTPUT_DESTROY}

#ENV_LIVE check needs more thought for being generic.  this was pretty specific to the jenkins/nexus setup.
.PHONY: not-live
not-live:
	if [ "${ENV}" == "${ENV_LIVE}" ] ; then echo "${ENV} env is live" ; false ; fi

.PHONY: pull-remote-state
pull-remote-state: terraform ## Pull remote state from storage
	terraform state pull > ${TF_PULLED_STATE}
	echo "ran 'terraform state pull' remote state downloaded to ${TF_PULLED_STATE}."

.PHONY: push-remote-state
push-remote-state: terraform ## Push local pulled state to remote storage
	terraform state push -lock=true ${TF_PULLED_STATE}
	echo "ran 'terraform state push' remote state ${TF_PULLED_STATE} uploaded."

.PHONY: open-backend-bucket
open-backend-bucket: ## Open terraform backend S3 bucket
	echo "${REGION}"
	echo "${BUCKET}"
	echo "${KEY}"
	open "https://s3.console.aws.amazon.com/s3/object/${BUCKET}/${KEY}"

ENVIRONMENT := $(shell echo "${ENV}" | sed "s/\/.*$$//")
AWS_REGION := $(shell echo "${ENV}" | sed "s/^.*\///")
IS_PR := $(shell echo "${ENV}" | grep -e "^PR-")
.PHONY: create-pr-configs
create-pr-configs: sponge sed cp ## create PR environment configs from PR template
	echo "ENVIRONMENT=[${ENVIRONMENT}]"
	echo "AWS_REGION=[${AWS_REGION}]"
	echo "IS_PR=[${IS_PR}]"
	{ [ -z "${IS_PR}" ] && echo "ENV is not a PR: ${ENV}" && exit 1 ; } || true

	cp -TR ${ENV_PATH}/PR ${ENV_PATH}/${ENVIRONMENT}
	cat ${TF_BACKEND_CONFIG} | sed 's/JENKINS_SET_ENVIRONMENT/${ENVIRONMENT}/g' | sponge ${TF_BACKEND_CONFIG}
	cat ${TF_VARS}           | sed 's/JENKINS_SET_ENVIRONMENT/${ENVIRONMENT}/g' | sponge ${TF_VARS}

CONFIG_PATH := ../.devops/${ENVIRONMENT}/${AWS_REGION}/ecs

.PHONY: ecs-deploy-pr
ecs-deploy-pr: ${CONFIG_PATH}/taskdefinition.json ${CONFIG_PATH}/servicecreate.json ${CONFIG_PATH}/serviceupdate.json ## deploy PR environment
	echo "ENVIRONMENT=[${ENVIRONMENT}]"
	echo "AWS_REGION=[${AWS_REGION}]"
	echo "IS_PR=[${IS_PR}]"
	aws --no-cli-pager --profile ${AWS_PROFILE} --region ${AWS_REGION} ecs register-task-definition --cli-input-json file://${CONFIG_PATH}/taskdefinition.json
	aws --no-cli-pager --profile ${AWS_PROFILE} --region ${AWS_REGION} ecs create-service --cli-input-json file://${CONFIG_PATH}/servicecreate.json || \
	aws --no-cli-pager --profile ${AWS_PROFILE} --region ${AWS_REGION} ecs update-service --cli-input-json file://${CONFIG_PATH}/serviceupdate.json
