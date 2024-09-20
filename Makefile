.DEFAULT_GOAL := all

HOMEBREW := $(shell command -v brew 2>/dev/null)

all: brew_bundle dotfile_update

.PHONY: all
all:
	$(MAKE) brew_bundle
	$(MAKE) dotfile_update
	$(MAKE) update_vscode_config

.PHONY: brew_bundle
brew_bundle: required_homebrew
	brew bundle

.PHONY: dotfile_update
dotfile_update:
	chezmoi update

.PHONY: install_homebrew
install_homebrew:
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

.PHONY: update_vscode_config
update_vscode_config:
	bash vscode/install.sh

.PHONY: required_homebrew
required_homebrew:
ifndef HOMEBREW
	@echo "Homebrew is not installed. Installing Homebrew..."
	@$(MAKE) install_homebrew
else
	@echo "Homebrew is already installed."
endif
