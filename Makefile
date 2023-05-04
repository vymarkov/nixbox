BUILDER_virtualbox_PROVIDER = virtualbox
BUILDER_qemu_PROVIDER = libvirt

BUILDER ?= qemu.qemu
PROVIDER := $(BUILDER_$(word 2, $(subst ., ,${BUILDER}))_PROVIDER) 
NIXOS_VERSION ?= 22.11
BUILD_VERSION ?= $(shell date +%y%m%d%H%M%S)
ARCH ?= x86_64
REPO ?= hennersz/nixos
USE_FLAKES ?= true
BOOT_WAIT ?= 120s

ifeq (${USE_FLAKES}, true)
	FQ_NAME = ${REPO}-${NIXOS_VERSION}-flakes
	LOCAL_NAME = nixbox-${NIXOS_VERSION}-flakes
else
  FQ_NAME = ${REPO}-${NIXOS_VERSION}
	LOCAL_NAME = nixbox-${NIXOS_VERSION}
endif

all: help

help: ## This help
	@find . -name Makefile -o -name "*.mk" | xargs -n1 grep -hE '^[a-z0-9\-]+:.* ##' | sed 's/\: .*##/:/g' | sort | column  -ts':'

version:
	@echo "Build for ${ARCH} architecture and using the ${NIXOS_VERSION} NixOS iso version"

build: version nixos.pkr.hcl ## [BUILDER] [ARCH] [VERSION] Build packer image
	@packer build \
	-var arch=${ARCH} \
	-var builder="${BUILDER}" \
	-var version=${NIXOS_VERSION} \
	-var use_flakes=${USE_FLAKES} \
	-var boot_wait=${BOOT_WAIT} \
	-var iso_checksum="$(shell curl -sL https://channels.nixos.org/nixos-${NIXOS_VERSION}/latest-nixos-minimal-${ARCH}-linux.iso.sha256 | grep -Eo '^[0-9a-z]{64}')" \
	--only=${BUILDER} \
	nixos.pkr.hcl

build-all: ## [BUILDER] [VERSION] Build packer image
	@${MAKE} BUILDER=${BUILDER} VERSION=${NIXOS_VERSION} ARCH=x86_64 build
	@${MAKE} BUILDER=${BUILDER} VERSION=${NIXOS_VERSION} ARCH=i686 build

vagrant-plugin:
	@vagrant plugin list | grep vagrant-nixos-plugin || vagrant plugin install vagrant-nixos-plugin

vagrant-add:
	@test -f nixos-${NIXOS_VERSION}-${BUILDER}-${ARCH}.box && ARCH=${ARCH} vagrant box add --provider ${PROVIDER} --force ${LOCAL_NAME}-${BUILD_VERSION} nixos-${NIXOS_VERSION}-${BUILDER}-${ARCH}.box	
	@echo ${BUILD_VERSION} > .buildversion

vagrant-up: ## Try builded vagrant box
	@test -f .buildversion && BOX_NAME=${LOCAL_NAME}-$(shell cat .buildversion) vagrant up

vagrant-ssh: ## Connect to vagrant box
	@test -f .buildversion && BOX_NAME=${LOCAL_NAME}-$(shell cat .buildversion) vagrant ssh

vagrant-test: ## Connect to vagrant box
	@test -f .buildversion && BOX_NAME=${LOCAL_NAME}-$(shell cat .buildversion) vagrant ssh -c 'nix --version'

vagrant-destroy: ## Destroy vagrant box
	@test -f .buildversion && BOX_NAME=${LOCAL_NAME}-$(shell cat .buildversion) vagrant destroy

vagrant-push:
	@test -f nixos-${NIXOS_VERSION}-${BUILDER}-${ARCH}.box && ARCH="${ARCH}" vagrant cloud publish \
	--force \
	--release \
	--no-private \
	--description "$(shell cat ./Description.txt)" \
	--version-description "$(shell cat ./Description.txt)" \
	--short-description "NixOS ${NIXOS_VERSION}" \
	${FQ_NAME} ${NIXOS_VERSION}.${BUILD_VERSION} ${PROVIDER} nixos-${NIXOS_VERSION}-${BUILDER}-${ARCH}.box