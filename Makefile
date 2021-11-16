export AWS_DEFAULT_REGION := eu-west-1
export AWS_DEFAULT_OUTPUT := json
export AWS_PROFILE := default

export AWS_CLOUDFORMATION_STACK_FILE := stack.yml
export AWS_CLOUDFORMATION_STACK_NAME := aws-basic-network
export AWS_CLOUDFORMATION_STACK_TAGS := Owner=Daniel Email=daniel@segura.systems

export JINJA_CONFIG := config.yml
export JINJA_TEMPLATE := stack.yml.j2

export PYTHON_VIRTUAL_ENVIRONMENT := .venv
export PYTHON_REQUIREMENTS_FILE := requirements.txt

.DEFAULT_GOAL := create

define activate
	(. ${PYTHON_VIRTUAL_ENVIRONMENT}/bin/activate && $1;)
endef

${PYTHON_VIRTUAL_ENVIRONMENT}: $(PYTHON_REQUIREMENTS_FILE)
	python3 -m venv ${PYTHON_VIRTUAL_ENVIRONMENT}
	$(call activate, pip install -U pip)
	$(call activate, pip install -U -r $(PYTHON_REQUIREMENTS_FILE))

${AWS_CLOUDFORMATION_STACK_FILE}: ${PYTHON_VIRTUAL_ENVIRONMENT} ${JINJA_CONFIG} ${JINJA_TEMPLATE}
	$(call activate, j2 -o $@ ${JINJA_TEMPLATE} ${JINJA_CONFIG})

.PHONY: create
create: ${AWS_CLOUDFORMATION_STACK_FILE}

.PHONY: clean
clean:
	rm -rf ${PYTHON_VIRTUAL_ENVIRONMENT} ${AWS_CLOUDFORMATION_STACK_FILE}

.PHONY: plan
plan: create
	$(call activate, aws cloudformation deploy \
		--stack-name ${AWS_CLOUDFORMATION_STACK_NAME} \
		--template-file ${AWS_CLOUDFORMATION_STACK_FILE} \
		--tags ${AWS_CLOUDFORMATION_STACK_TAGS}
		--no-execute-changeset)

.PHONY: apply
apply: create
	$(call activate, aws cloudformation deploy \
		--stack-name ${AWS_CLOUDFORMATION_STACK_NAME} \
		--template-file ${AWS_CLOUDFORMATION_STACK_FILE} \
		--tags ${AWS_CLOUDFORMATION_STACK_TAGS})

.PHONY: destroy
destroy:
	$(call activate, aws cloudformation delete-stack \
		--stack-name ${AWS_CLOUDFORMATION_STACK_NAME})
	$(call activate, aws cloudformation wait stack-delete-complete \
		--stack-name ${AWS_CLOUDFORMATION_STACK_NAME})
