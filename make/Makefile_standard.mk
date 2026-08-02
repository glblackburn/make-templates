default: help

.PHONY: clean
clean: ## Removes all files in the .gitignore
	git clean -fdX

.PHONY: help
help: ## Show make targets
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
