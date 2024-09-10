.PHONY: all
all:
	$(MAKE) brew_bundle
	$(MAKE) dotfile_update

.PHONY: brew_bundle
brew_bundle:
	brew bundle

.PHONY: dotfile_update
dotfile_update:
	chezmoi update

