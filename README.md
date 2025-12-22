# Make Templates

A collection of reusable Makefile templates and scripts for various technologies and deployment scenarios.

## Table of Contents

- [Setting Up This Project in Your Project](#setting-up-this-project-in-your-project)
  - [Step 1: Create a Makefile in Your Project](#step-1-create-a-makefile-in-your-project)
  - [Step 2: Initialize the Templates](#step-2-initialize-the-templates)
  - [Step 3: Use the Templates](#step-3-use-the-templates)
  - [Example: Terraform Project](#example-terraform-project)
  - [Example: Docker Project](#example-docker-project)
  - [Updating Templates](#updating-templates)
  - [Notes](#notes)
- [Usage Summary](#usage-summary)
  - [Docker Templates](#docker-templates)
  - [AWS Templates](#aws-templates)
  - [Docker Scripts](#docker-scripts)
  - [Make Templates](#make-templates)
- [Configuration](#configuration)
- [TODO](#todo)

## Setting Up This Project in Your Project

To use these Makefile templates in your own project, follow this standardized pattern:

### Step 1: Create a Makefile in Your Project

Create a `Makefile` in your project root with the following structure:

```makefile
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

SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.SHELLFLAGS = -uec -o pipefail

modules := $(shell find .make -name "Makefile_*.mk" 2>/dev/null)
-include $(modules)

default: .make

.make: ## get the make file templates
	git -C .make pull || git clone git@github.com:glblackburn/make-templates.git .make
```

**Important:** Add `.make/` to your `.gitignore` file:

```gitignore
# Ignore .make directory - this is cloned from the make-templates repository
.make/
```

The `.make` directory should not be committed to your repository as it contains a clone of this repository that is automatically managed by the Makefile.

### Step 2: Initialize the Templates

Run `make` in your project directory. This will:
- Clone the make-templates repository into a `.make` directory
- Load all available Makefile modules
- Make all template targets available

```bash
make
```

### Step 3: Use the Templates

After initialization, you can use any of the available template targets. Run `make help` to see all available commands:

```bash
make help
```

### Example: Terraform Project

For a Terraform project, you might extend the base Makefile like this:

```makefile
# Standard Terraform Make Pattern
# 
# This Makefile follows the standardized pattern:
# 1. Ensures .make directory exists with latest templates
# 2. Includes makefile modules from .make/
# 3. Uses ENV variable for environment selection
# 4. Supports standard terraform operations (plan, apply, destroy)
#
# Usage:
#   make                    # Initialize .make directory
#   make show-envs         # List available environments  
#   make plan ENV=dev      # Run terraform plan for dev environment
#   make apply ENV=dev     # Run terraform apply for dev environment

SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.SHELLFLAGS = -uec -o pipefail

## ENV options are in environments folder.
## Example: ENV=dev make plan
ENV_DEFAULT := dev/us-east-1
ENV         := $(if $(ENV),$(ENV),$(ENV_DEFAULT))
ENV_PATH    := ../environments
ENV_PREFIX  := $(ENV_PATH)/$(ENV)
OUT_PREFIX  := output/$(ENV)

modules := $(shell find .make -name "Makefile_*.mk" 2>/dev/null)
-include $(modules)

default: .make

.make: ## get the make file templates
	git -C .make pull || git clone git@github.com:glblackburn/make-templates.git .make
```

**Remember:** Add `.make/` to your `.gitignore` file.

### Example: Docker Project

For a Docker project, set the required variables and use Docker targets:

```makefile
# Standard Make Pattern for Docker Project

SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.SHELLFLAGS = -uec -o pipefail

# Set project-specific variables
PROJECT_NAME = my-project
DOCKER_HOST = your-registry.com
ENVIRONMENT = dev

modules := $(shell find .make -name "Makefile_*.mk" 2>/dev/null)
-include $(modules)

default: .make

.make: ## get the make file templates
	git -C .make pull || git clone git@github.com:glblackburn/make-templates.git .make
```

**Remember:** Add `.make/` to your `.gitignore` file.

Then use Docker targets:
```bash
make docker-info    # Show Docker configuration
make docker-build   # Build Docker image
make docker-push    # Push to registry
```

### Updating Templates

The `.make` target automatically pulls the latest templates. To manually update:

```bash
make .make
```

Or directly:
```bash
git -C .make pull
```

### Notes

- The `.make` directory is created in your project root and contains a clone of this repository
- The `.make` directory should be added to your `.gitignore` file
- All template functionality is available after running `make` once
- Templates are automatically included from `.make/make/Makefile_*.mk`

## Usage Summary

### Docker Templates

#### Required Variables
Before using the Docker templates, set these required variables:

```bash
# Required: Docker registry host
export DOCKER_HOST=your-registry.com

# Optional: Docker mirror registry (defaults to empty if not set)
export DOCKER_MIRROR=https://your-mirror-registry.com

# Optional: Docker login buckets for AWS Elastic Beanstalk
export DOCKER_LOGIN_BUCKET_PROD=your-prod-docker-login-bucket
export DOCKER_LOGIN_BUCKET_DEV=your-dev-docker-login-bucket

# Optional: Debug Git repository for git-sync container
export DEBUG_GIT_URL=git@github.com:your-org/your-debug-repo.git
```

#### Using Docker Makefile
```makefile
# In your project's Makefile
DOCKER_HOST = your-registry.com
include make/Makefile_docker.mk

# Or set via environment variable
# export DOCKER_HOST=your-registry.com
# make docker-build
```

#### Available Docker Targets
- `make docker-info` - Show all Docker variables
- `make docker-build` - Build Docker image
- `make docker-run` - Run Docker image and open in browser
- `make docker-push` - Push Docker image to registry

### AWS Templates

#### Elastic Beanstalk
- `aws/eb/build.sh` - Build script for Elastic Beanstalk deployments

#### Route53
- `aws/route53/create.sh` - DNS record creation script

### Docker Scripts

#### Configuration Scripts
- `docker/build.sh` - Docker build script
- `docker/configs.sh` - Docker configuration script (generates AWS EB configs)
- `docker/debug.sh` - Docker debugging script
- `docker/dependencies.sh` - Docker dependencies script
- `docker/push.sh` - Docker push script

### Make Templates

#### Available Makefile Modules
- `make/Makefile_docker.mk` - Docker operations
- `make/Makefile_package_json.mk` - Node.js package.json operations
- `make/Makefile_software.mk` - Software build operations
- `make/Makefile_standard.mk` - Standard operations
- `make/Makefile_terraform.mk` - Terraform operations

#### Utility Scripts
- `make/read-property.sh` - Property reading utility
- `make/README_docker.md` - Docker-specific documentation

## Configuration

All templates are designed to be configurable through environment variables or Makefile variables. See individual template files for specific configuration options.

## TODO
