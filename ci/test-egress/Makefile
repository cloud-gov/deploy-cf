SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deploy-env: ## Deploy org, spaces, and apps to CF
	./deploy-env.sh

run-tests: ## Run tests against deployed apps
	./run-tests

clean: ## Remove test apps, spaces, and orgs from CF

all: deploy-env run-tests clean ## Run deploy-env, run-tests, and clean
