#!/bin/bash

# vscode open -> Command + Shift + P-> shell -> code install

# Visual Studio Code :: Package list

pkglist=(
negokaz.live-server-preview
pkief.material-icon-theme
shardulm94.trailing-spaces
coenraads.bracket-pair-colorizer
abusaidm.html-snippets
ecmel.vscode-html-css
zignd.html-css-class-completion
kisstkondoros.vscode-gutter-preview
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done
