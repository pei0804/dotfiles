all: submodule install

submodule:
	git submodule init
	git submodule update

install: vimperator/vimperator-plugins link

vim/autoload/plug.vim:
	curl -fLo $@ --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

vimperator/vimperator-plugins:
	git clone https://github.com/vimpr/vimperator-plugins.git $@
	ln -s $@/plugin_loader.js vimperator/plugin/

PWD:=$(shell pwd)
srcs:=vimrc vim vimperator vimperatorrc gitconfig zshrc ideavimrc tmux.conf
link:
	$(foreach src,$(srcs),ln -Fs $(PWD)/$(src) $(HOME)/.$(src);)

update-vimperator-plugins:
	cd ./vimperator/vimperator-plugins && git pull origin master

deps: vim/autoload/plug.vim
	mkdir -p $(HOME)/.vimtmp
	mkdir -p $(HOME)/.vimback
/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"