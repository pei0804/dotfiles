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
coenraads.bracket-pair-colorizer
dbaeumer.vscode-eslint
oderwat.indent-rainbow
ms-vsliveshare.vsliveshare
esbenp.prettier-vscode
hinnn.stylelint
vscode-icons-team.vscode-icons
k--kato.intellij-idea-keybindings
vscodevim.vim
msjsdiag.debugger-for-chrome
editorconfig.editorconfig
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done
