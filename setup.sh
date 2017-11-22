#!/bin/bash

echo ' ___  ___      _______       ___           ___           ________          '
echo '|\  \|\  \    |\  ___ \     |\  \         |\  \         |\   __  \         '
echo '\ \  \\\  \   \ \   __/|    \ \  \        \ \  \        \ \  \|\  \        '
echo ' \ \   __  \   \ \  \_|/__   \ \  \        \ \  \        \ \  \\\  \       '
echo '  \ \  \ \  \   \ \  \_|\ \   \ \  \____    \ \  \____    \ \  \\\  \      '
echo '   \ \__\ \__\   \ \_______\   \ \_______\   \ \_______\   \ \_______\     '
echo '    \|__|\|__|    \|_______|    \|_______|    \|_______|    \|_______|     '
echo ' ___       __       ________      ________      ___           ________     '
echo '|\  \     |\  \    |\   __  \    |\   __  \    |\  \         |\   ___ \    '
echo '\ \  \    \ \  \   \ \  \|\  \   \ \  \|\  \   \ \  \        \ \  \_|\ \   '
echo ' \ \  \  __\ \  \   \ \  \\\  \   \ \   _  _\   \ \  \        \ \  \ \\ \  '
echo '  \ \  \|\__\_\  \   \ \  \\\  \   \ \  \\  \|   \ \  \____    \ \  \_\\ \ '
echo '   \ \____________\   \ \_______\   \ \__\\ _\    \ \_______\   \ \_______\'
echo '    \|____________|    \|_______|    \|__|\|__|    \|_______|    \|_______|'
echo ''
cd ~
echo 'generate keypair?[Y/n]'
read ANSWER

case $ANSWER in
  "" | "Y" | "y" )
    ssh-keygen;;
  * ) echo "generate keypair skip";;
esac

echo '---------------------'

echo 'clone dotfiles?[Y/n]'
read ANSWER
case $ANSWER in
  "" | "Y" | "y" )
    git clone https://github.com/pei0804/dotfiles.git;;
  * ) echo "clone dotfiles skip";;
esac

echo '---------------------'

echo 'install homebrew?[Y/n]'
read ANSWER
case $ANSWER in
  "" | "Y" | "y" )
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";;
  * ) echo "install homebrew skip";;
esac

echo '---------------------'

echo 'install ansible?[Y/n]'
read ANSWER
case $ANSWER in
  "" | "Y" | "y" )
    brew install python
    brew install ansible
    rehash;;
  * ) echo "install ansible skip";;
esac

echo '---------------------'

echo 'run ansible?[Y/n]'
read ANSWER
case $ANSWER in
  "" | "Y" | "y" )
    cd ~/dotfiles
    HOMEBREW_CASK_OPTS="--appdir=/Applications" ansible-playbook -i hosts -vv localhost.yaml;;
  * ) echo "run ansible skip";;
esac

echo '---------------------'

echo 'vim setup?[Y/n]'
read ANSWER
case $ANSWER in
  "" | "Y" | "y" )
	mkdir -p ~/.vimtmp
	mkdir -p ~/.vimback
	curl -fLo $@ --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim;;
  * ) echo "install ansible skip";;
esac

echo '---------------------'

echo 'new Mac setup finished!! Please run chsh /bin/zsh'
