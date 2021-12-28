# Commodore takes the root dir name as the component name
COMPONENT_NAME ?= $(shell basename ${PWD} | sed s/component-//)

compiled_path   ?= compiled/$(COMPONENT_NAME)/$(COMPONENT_NAME)
root_volume     ?= -v "$${PWD}:/$(COMPONENT_NAME)"
compiled_volume ?= -v "$${PWD}/$(compiled_path):/$(COMPONENT_NAME)"
commodore_args  ?= --search-paths ./dependencies --search-paths .

# Determine whether to use podman
#
# podman currently fails when executing in GitHub actions on Ubuntu LTS 20.04,
# so we never use podman if GITHUB_ACTIONS==true.
use_podman := $(shell command -v podman 2>&1 >/dev/null; p="$$?"; \
		if [ "$${GITHUB_ACTIONS:-false}" != "true" ]; then echo "$$p"; else echo 1; fi)

ifeq ($(use_podman),0)
	DOCKER_CMD   ?= podman
	DOCKER_ARGS  ?= run --rm -u "$$(id -u):$$(id -g)" --userns=keep-id -w /$(COMPONENT_NAME)
else
	DOCKER_CMD   ?= docker
	DOCKER_ARGS  ?= run --rm -u "$$(id -u):$$(id -g)" -w /$(COMPONENT_NAME)
endif

JSONNET_FILES   ?= $(shell find . -type f -not -path './vendor/*' \( -name '*.*jsonnet' -or -name '*.libsonnet' \))
JSONNETFMT_ARGS ?= --in-place --pad-arrays
JSONNET_IMAGE   ?= docker.io/bitnami/jsonnet:latest
JSONNET_DOCKER  ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) --entrypoint=jsonnetfmt $(JSONNET_IMAGE)

YAMLLINT_ARGS   ?= --no-warnings
YAMLLINT_CONFIG ?= .yamllint.yml
YAMLLINT_IMAGE  ?= docker.io/cytopia/yamllint:latest
YAMLLINT_DOCKER ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) $(YAMLLINT_IMAGE)

VALE_CMD  ?= $(DOCKER_CMD) $(DOCKER_ARGS) $(root_volume) --volume "$${PWD}"/docs/modules:/pages docker.io/vshn/vale:2.1.1
VALE_ARGS ?= --minAlertLevel=error --config=/pages/ROOT/pages/.vale.ini /pages

ANTORA_PREVIEW_CMD ?= $(DOCKER_CMD) run --rm --publish 2020:2020 --volume "${PWD}":/antora vshn/antora-preview:2.3.3 --style=syn --antora=docs

COMMODORE_CMD  ?= $(DOCKER_CMD) $(DOCKER_ARGS) --security-opt label=disable $(root_volume) docker.io/projectsyn/commodore:latest component compile . $(commodore_args)
JB_CMD         ?= $(DOCKER_CMD) $(DOCKER_ARGS) --entrypoint /usr/local/bin/jb docker.io/projectsyn/commodore:latest install

instance ?= defaults
