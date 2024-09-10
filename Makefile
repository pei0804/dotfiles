.PHONY: all
all:
	brew_bundle
	chezmoi update

.PHONY: brew_bundle
brew_bundle:
	brew bundle
