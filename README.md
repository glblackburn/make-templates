# Make Templates

A collection of reusable Makefile templates and scripts for various technologies and deployment scenarios.

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
