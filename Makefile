all: submodule install

submodule:
	git submodule init
	git submodule update

install: vimperator/vimperator-plugins link

vimperator/vimperator-plugins:
	git clone https://github.com/vimpr/vimperator-plugins.git $@
	ln -s $@/plugin_loader.js vimperator/plugin/

PWD:=$(shell pwd)
srcs:=vimrc vimperator vimperatorrc gitconfig zshrc ideavimrc
link:
	$(foreach src,$(srcs),ln -Fs $(PWD)/$(src) $(HOME)/.$(src);)

update-vimperator-plugins:
	cd ./vimperator/vimperator-plugins && git pull origin master
