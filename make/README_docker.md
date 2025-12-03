# Building a docker image

Leverage `make` to build and publish the docker image.  To get a list of
commands run `make` alone.  The inital run will download the make
templates from GitHub and setup the framework into the `.make`
directory.  Run 'make' again to list the available commands.  The
commands needed will begin with `docker-`.

The make commands generate the needed docker tags and run the needed
command line options in a standard format.  For more details, see the
`README_docker.md` and `Makefile_docker.mk` file in the `.make`
directory.

## Docker tags

The docker tags are defined a few variables.  The default values for
the docker tags are based on the git SHA of the latest commit.

* PROJECT_NAME -
set in project Makefile.  No default value.

* PROJECT_VERSION -
Typcally set by Jenkins.  Can be set in project Makefile.  Defaults to git sha.

* BUILD_NUMBER - 
Typcally set by Jenkins.  Can be set in project Makefile.  Defaults to git sha.

WARNING: It is possible to lose and overwrite existing docker image
tags in the remote docker repository when changes are built and pushed
to the docker repository before committing to git.  As components of
the docker tag default to the current git sha, changes should be
committed locally prior to building the docker image.  Otherwise, the
local docker tags for the image will need to be removed and changes
committed to git prior to rebuilding the docker image and pushing to
the remote docker repository.

## Building the image
run `make docker-build`

## Display information about the currnet docker build
run `make docker-info`

## Run image in the forground to test out changes
run `make docker-run-forground`

## Push image to the remote docker repository in Nexus
run `make docker-push`
