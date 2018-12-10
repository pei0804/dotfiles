#!/bin/bash

git clone https://github.com/powerline/fonts.git --depth=1
cd fonts
./install.sh
cd ..
rm -rf fonts

git clone https://github.com/riywo/anyenv ~/.anyenv
pyenv install 2.7.11
CFLAGS="-I$(brew --prefix readline)/include -I$(brew --prefix openssl)/include -I$(xcrun --show-sdk-path)/usr/include" \
LDFLAGS="-L$(brew --prefix readline)/lib -L$(brew --prefix openssl)/lib" \
PYTHON_CONFIGURE_OPTS=--enable-unicode=ucs2 \
pyenv install -v 3.6.6
pyenv virtualenv 2.7.11 neovim2
pyenv virtualenv 3.6.6 neovim3
pyenv activate neovim2
pip install neovim
pyenv activate neovim3
pip install neovim
