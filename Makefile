# Makefile
#
# Usage:
#   make all

WORKSPACE=$(shell echo $$HOME/Packer/packer-centos-pdk)
DEBUG_BOX_PATH=$(WORKSPACE)/tmp
BOX_PATH=$(WORKSPACE)/package.box
VAGRANT_CLOUD_ACCESS_TOKEN?=my-secret-packer-cloud-token
PACKER_BUILD_OPTS=-var 'workspace=$(WORKSPACE)' -var 'access_token=$(VAGRANT_CLOUD_ACCESS_TOKEN)'

.PHONY: setup clean validate build

all: setup \
	clean \
	validate \
	build

setup:
	@mkdir -p $(WORKSPACE)

clean:
	@rm -fr $(WORKSPACE)/*.box || echo "No old boxes found."

validate:
	packer validate ${PACKER_BUILD_OPTS} templates/packer-centos.json

build:
	PACKER_LOG=1 \
	packer build ${PACKER_BUILD_OPTS} -force templates/packer-centos.json

test: test-setup register
	cd ~/Packer/tmp/test/vagrant ; \
    vagrant init -f vagrant-debug; \
	vagrant up; \
	vagrant ssh; \
	vagrant destroy -f

test-setup:
	@mkdir -p ~/Packer/tmp/test/vagrant
	@mkdir -p $(DEBUG_BOX_PATH)

register:
	vagrant box add -f vagrant-debug $(BOX_PATH)