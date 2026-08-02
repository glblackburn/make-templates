GIT_HUB=$(shell git remote -v | head -1 | sed "s/:/\//" | sed 's/^.*git@\(.*\)\.git.*$$/https:\/\/\1/')
GIT_SHA=$(shell git rev-parse --short HEAD^{commit})
BRANCH=$(shell git branch --show-current)

standard-info: standard-vars ## show info from standard template
	@echo "GIT_HUB        =[${GIT_HUB}]"
	@echo "GIT_SHA        =[${GIT_SHA}]"
	@echo "BRANCH         =[${BRANCH}]"

.PHONY: open-github
open-github: standard-vars ## open GitHub to the repo for this project in the browser.
	open "${GIT_HUB}"

.PHONY: create-pull-request
create-pull-request: standard-vars ## open GitHub to create a pull request for this branch in the browser.
	open "${GIT_HUB}/pull/new/${BRANCH}"

.PHONY: make-dirs-git-status
make-dirs-git-status: ## Run git status for all .make dirs in subfolders
	find . -type d -name .make | while read dir ; do echo "== $${dir}" ; git -C $${dir} status ; done

.PHONY: make-dirs-git-pull
make-dirs-git-pull: ## Run git pull for all .make dirs in subfolders
	find . -type d -name .make | while read dir ; do echo "== $${dir}" ; git -C $${dir} pull ; done

