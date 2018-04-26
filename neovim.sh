#!/bin/bash

git clone https://github.com/powerline/fonts.git --depth=1\n
cd fonts
./install.sh\n
cd ..\n
rm -rf fonts\n

git clone https://github.com/riywo/anyenv ~/.anyenv
pyenv install 2.7.11
pyenv install 3.4.4
pyenv virtualenv 2.7.11 neovim2
pyenv virtualenv 3.4.4 neovim3
pyenv activate neovim2
pip install neovim
pyenv activate neovim3
pip install neovim