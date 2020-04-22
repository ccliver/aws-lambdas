.DEFAULT_GOAL := help

TERRAFORM_VERSION := 0.12.24
DOCKER_OPTIONS := -v ${PWD}/${TARGET}:/terraform \
-w /terraform \
-it \
-e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
-e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

init: ## Initialize the Terraform state: TARGET=<projectSubDir> make init
	docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} init -upgrade=true

plan: ## Run a Terraform plan: TARGET=<projectSubDir> make apply
	docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} plan

apply: ## Create the resources with Terraform: TARGET=<projectSubDir> make apply
	docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} apply

destroy: ## Destroy the AWS resources with Terraform: TARGET=<projectSubDir> make apply
	docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} destroy

adhoc: ## Run an ad hoc Terraform command: COMMAND=version TARGET=<projectSubDir> make apply
	docker run ${DOCKER_OPTIONS} hashicorp/terraform:${TERRAFORM_VERSION} ${COMMAND}

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'