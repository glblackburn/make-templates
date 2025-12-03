SHELL=/bin/bash
.EXPORT_ALL_VARIABLES:
.SHELLFLAGS = -uec -o pipefail

modules := $(shell find . -name "Makefile_*.mk")
include $(modules)
