NVIM ?= nvim

AUTO_TEST_DIR := test/auto

unexport NVIM_LISTEN_ADDRESS

XDG_CONFIG_HOME := $(AUTO_TEST_DIR)/.config_home
XDG_DATA_HOME := $(AUTO_TEST_DIR)/.data_home
export XDG_CONFIG_HOME XDG_DATA_HOME

NVIM_TEST_CFG := $(AUTO_TEST_DIR)/minimal_init.lua
NVIM_PACKER_COMPILED_FILE := $(XDG_CONFIG_HOME)/nvim/plugin/packer_compiled.vim

.PHONY: test
test: $(NVIM_PACKER_COMPILED_FILE) ## Run all tests.
	$(NVIM) --headless -u $(NVIM_TEST_CFG) -c "PlenaryBustedDirectory $(AUTO_TEST_DIR)/termmaker/ {minimal_init = '$(NVIM_TEST_CFG)'}"

$(NVIM_PACKER_COMPILED_FILE): $(NVIM_TEST_CFG)
	$(NVIM) --headless -u $(NVIM_TEST_CFG) -c "PackerSync" -c "autocmd! User PackerComplete qall"

.PHONY: clean
clean: ## Clean directory.
	rm -rf $(XDG_CONFIG_HOME)
	rm -rf $(XDG_DATA_HOME)

.PHONY: help
help: ## Show this help.
	@awk -F ':|##' '/^[^\t].+?:.*?##/ {\
		printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
	}' $(MAKEFILE_LIST)
