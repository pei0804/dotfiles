.DEFAULT_GOAL := all

HOMEBREW := $(shell command -v brew 2>/dev/null)

.PHONY: all
all: brew_bundle update_vscode_config mise_install dotfile_update 

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

.PHONY: mise_install
mise_install:
	mise install

.PHONY: required_homebrew
required_homebrew:
ifndef HOMEBREW
	@echo "Homebrew is not installed. Installing Homebrew..."
	@$(MAKE) install_homebrew
else
	@echo "Homebrew is already installed."
endif
