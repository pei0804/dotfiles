#!/bin/bash

# vscode open -> Command + Shift + P-> shell -> code install

# Visual Studio Code :: Package list

pkglist=(
negokaz.live-server-preview
)

for i in ${pkglist[@]}; do
  code --install-extension $i
done
