# -------------------------------------
# 環境変数
# -------------------------------------

# .config
export XDG_CONFIG_HOME=$HOME/.config

# GAE
export PATH=$HOME/go_appengine:$PATH

# The next line updates PATH for the Google Cloud SDK.
if [ -f /Users/jumpei/google-cloud-sdk/path.zsh.inc ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# The next line enables shell command completion for gcloud.
if [ -f $HOME/google-cloud-sdk/completion.zsh.inc ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# Go
export GOPATH=$HOME/go
export PATH=$PATH::$GOPATH/bin

# EDITER
export EDITOR=vim

# PATH
export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/bin:$PATH

# 文字コード
export LANG=ja_JP.UTF-8

# Dotfile
export DOTFILES=$HOME/dotfiles

# GAE
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/.config/gcloud/application_default_credentials.json

# JAVA
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`

# -------------------------------------
# zsh
# -------------------------------------

# History
HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# antigen
source $DOTFILES/antigen/antigen.zsh
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle git
antigen bundle command-not-found
antigen bundle golang
antigen bundle mafredri/zsh-async
antigen bundle sindresorhus/pure
antigen apply

autoload -U promptinit; promptinit
prompt pure

# THEME
ZSH_THEME=''

# 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct

# ビープを鳴らさない
setopt nobeep

# 色を使う
setopt prompt_subst

# ^Dでログアウトしない。
setopt ignoreeof

# バックグラウンドジョブが終了したらすぐに知らせる。
setopt no_tify

# 直前と同じコマンドをヒストリに追加しない
setopt hist_ignore_dups

# ヒストリを呼び出してから実行する間に一旦編集
setopt hist_verify

# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd

# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd

# iTerm2のタブ名を変更する
# cdしたあとで、自動的に ls する
function chpwd() { ls; echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print "/"$1"/"$2}'| rev)\007"}

# ヒストリを共有
setopt share_history

# -------------------------------------
# エイリアス
# -------------------------------------

# alias
alias ls="ls -G"
alias la="ls -laGF"
alias gl="git log --oneline --decorate --all --graph"
alias g='cd $(ghq root)/$(ghq list | peco)'
alias gh='hub browse $(ghq list | peco | cut -d "/" -f 2,3)'
alias htdocs='cd /Applications/XAMPP/xamppfiles/htdocs'
alias vimedit='vim ~/dotfiles/vimrc'
alias dotfiles='cd ~/dotfiles'
alias tags='~/dotfiles/Makefile create_tags TARGET_PATH=./'
alias vi='nvim'
alias vim='nvim'
alias ctags="`brew --prefix`/bin/ctags"

# tree
alias tree="tree -NC" # N: 文字化け対策, C:色をつける

# -------------------------------------
# version
# -------------------------------------

# anyenv
# https://github.com/riywo/anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# envrc
eval "$(direnv hook zsh)"
