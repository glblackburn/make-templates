# Standard Make Pattern
# 
# This Makefile follows the standardized pattern:
# 1. Ensures .make directory exists with latest templates
# 2. Includes makefile modules from .make/
# 3. Provides access to all template functionality
#
# Usage:
#   make                    # Initialize .make directory
#   make help               # Show all available targets
#
# For projects using this repository:
#   See README.md for detailed setup instructions and usage examples.

SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.SHELLFLAGS = -uec -o pipefail

modules := $(shell find .make -name "Makefile_*.mk" 2>/dev/null)
-include $(modules)

default: .make

.make: ## get the make file templates
	git -C .make pull || git clone git@github.com:glblackburn/make-templates.git .make

.PHONY: usage-example
usage-example: ## Show example usage in a project Makefile
	@echo "Example Makefile for using this repository:"
	@echo ""
	@echo "# Standard Make Pattern"
	@echo "#"
	@echo "# This Makefile follows the standardized pattern:"
	@echo "# 1. Ensures .make directory exists with latest templates"
	@echo "# 2. Includes makefile modules from .make/"
	@echo "# 3. Provides access to all template functionality"
	@echo "#"
	@echo "# Usage:"
	@echo "#   make                    # Initialize .make directory"
	@echo "#   make help               # Show all available targets"
	@echo ""
	@echo "SHELL=/bin/bash"
	@echo ".EXPORT_ALL_VARIABLES:"
	@echo ".SHELLFLAGS = -uec -o pipefail"
	@echo ""
	@echo "modules := \$$(shell find .make -name \"Makefile_*.mk\" 2>/dev/null)"
	@echo "-include \$$(modules)"
	@echo ""
	@echo "default: .make"
	@echo ""
	@echo ".make: ## get the make file templates"
	@echo "	git -C .make pull || git clone git@github.com:glblackburn/make-templates.git .make"
	@echo ""
	@echo "Example .gitignore entry:"
	@echo ""
	@echo "# Ignore .make directory - this is cloned from the make-templates repository"
	@echo ".make/"
	@echo ""
