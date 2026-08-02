# https://brew.sh/
VPATH=${HOME}/bin:${HOME}/.jenv/shims:${HOME}/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin:${PATH}
UNAME := $(shell uname -s)

default: help

brew:
	make install-homebrew

install-homebrew: ## install homebrew to download other pacakges
	@echo "install Homebrew package manager see: https://brew.sh/"
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@echo "################################################################################"
	@echo "Follow the Homebrew setup instructions above and rerun your command."
	@echo "################################################################################"
	exit 1

aws: ## install aws cli
	brew install awscli

# https://github.com/tfutils/tfenv
tfenv:
	@echo "tfenv: PATH=[${PATH}]"
	@echo "tfenv: VPATH=[${VPATH}]"
	make install-tfenv
	@echo "tfenv: after make install-tfenv"
	which tfenv
	@echo "tfenv: after which tfenv"

install-tfenv: brew gcc ## install tfenv to manage terraform versions
	brew install tfenv

sponge:
	make install-sponge

.PHONY: install-sponge
install-sponge: ## install sponge
	@echo UNAME=$(UNAME)
ifeq ($(UNAME),Linux)
	make apk-install-moreutils
endif
ifeq ($(UNAME),Darwin)
	make brew-install-sponge
endif

.PHONY: brew-install-sponge
brew-install-sponge: brew
	brew install sponge

.PHONY: apk-install-moreutils
apk-install-moreutils: apk
	apk add --update --no-cache moreutils

gcc:
	make install-gcc

install-gcc:
	sudo yum -y install gcc

keeper:
	make install-keeper

install-keeper: python3 ## install keeper commander cli tool
	@echo "This is a manual install."
	open https://docs.keeper.io/secrets-manager/commander-cli/commander-installation-setup/installation-on-mac
	open https://github.com/Keeper-Security/Commander/releases/latest
	python3 --version
	pip3 --version
	keeper --version

terraform:
	make install-terraform

install-terraform: tfenv ## install terraform to manage infrastructure
	tfenv install ${TF_VERSION}
	tfenv use ${TF_VERSION}

jq:
	make install-jq

install-jq: brew ## install jq to query json files
	@echo "install jq to query json files"
	brew install jq

jenv:
	make install-jenv

install-jenv: brew ## install jenv to manage java versions
	@echo "install jenv to manage java versions. see: https://github.com/jenv/jenv"
	brew install jenv

	@echo "================================================================================"
	@echo "MAKE SURE TO SCROLL UP AND FOLLOW THE BREW INSTRUCTIONS"
	@echo "Run setup a second time after updating the .bash_profile and reloading"
	@echo "run: exec $$SHELL -l"
	@echo "run: jenv enable-plugin export"
	@echo "================================================================================"

# https://openjdk.java.net/
java:
	make install-java

install-java:
	@echo UNAME=$(UNAME)
ifeq ($(UNAME),Linux)
	sudo yum -y install java-1.8.0
endif
ifeq ($(UNAME),Darwin)
	make install-openjdk
endif

# https://formulae.brew.sh/formula/openjdk
install-openjdk: brew ## install openjdk
	@echo "install openjdk. see https://formulae.brew.sh/formula/openjdk"
	brew install openjdk
	jenv global 15
	jenv enable-plugin export

python3:
	make install-python

install-python: ## install python
	brew install python
	python3 --version
	pip3 --version

install-python-lib-git: pip3 ## install git python library
	pip3 install gitpython

install-python-lib-pandas: pip3 ## install git python library
	pip3 install pandas

/usr/local/bin/xmllint:
	make install-xmllint

install-xmllint: ## install xmllint
	@echo "install xmllint"
	@echo "no installer setup.  you'll have to do this manually."

xmlstarlet:
	make install-xmlstarlet

install-xmlstarlet: brew ## install xmlstarlet
	@echo "install xmlstarlet"
	brew install xmlstarlet

redis-cli:
	make install-redis

install-redis: brew ## install redis
	brew install redis

az:
	make install-azure-cli

install-azure-cli: brew ## install azure-cli
	brew install azure-cli

install-redis-linux: ## install redis on amazon linux
	sudo yum install -y amazon-linux-extras
	yes | sudo amazon-linux-extras install epel
	sudo yum update -y
	sudo yum install -y redis
	redis-cli --version
