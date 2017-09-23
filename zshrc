# -------------------------------------
# 環境変数
# -------------------------------------

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

# -------------------------------------
# zsh
# -------------------------------------

# 補完機能の強化
autoload -U compinit
compinit

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

# 補完
# タブによるファイルの順番切り替えをしない
# unsetopt auto_menu

# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd

# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd

# iTerm2のタブ名を変更する
# cdしたあとで、自動的に ls する
function chpwd() { ls; echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print "/"$1"/"$2}'| rev)\007"}

# ヒストリを共有
setopt share_history

# History
HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# antigen
source $DOTFILES/antigen/antigen.zsh
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen apply
antigen bundle git
antigen bundle mvn
antigen bundle golang

# THEME
ZSH_THEME="robbyrussell"

# -------------------------------------
# エイリアス
# -------------------------------------

# alias
alias zsh="source ~/.zshrc" # 謎のバグ対策zh
alias ls="ls -G"
alias la="ls -laGF"
alias gl="git log --oneline --decorate --all --graph"
alias g='cd $(ghq root)/$(ghq list | peco)'
alias gh='hub browse $(ghq list | peco | cut -d "/" -f 2,3)'
alias htdocs='cd /Applications/XAMPP/xamppfiles/htdocs'
alias vimedit='vim ~/dotfiles/vimrc'
alias dotfiles='cd ~/dotfiles'
alias tags='~/dotfiles/Makefile create_tags TARGET_PATH=./'

# tree
alias tree="tree -NC" # N: 文字化け対策, C:色をつける

# -------------------------------------
# git
# -------------------------------------

# ここはプロンプトの設定なので今回の設定とは関係ありません
if [ $UID -eq 0 ];then
# ルートユーザーの場合
PROMPT="%F{red}%n:%f%F{green}%d%f [%m] %%
"
else
# ルートユーザー以外の場合
PROMPT="%F{cyan}%n:%f%F{green}%d%f [%m] %%
"
fi


# ブランチ名を色付きで表示させるメソッド
function rprompt-git-current-branch {
  local branch_name st branch_status

  if [ ! -e  ".git" ]; then
    # gitで管理されていないディレクトリは何も返さない
    return
  fi
  branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  st=`git status 2> /dev/null`
  if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
    # 全てcommitされてクリーンな状態
    branch_status="%F{green}"
  elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
    # gitに管理されていないファイルがある状態
    branch_status="%F{red}?"
  elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
    # git addされていないファイルがある状態
    branch_status="%F{red}+"
  elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
    # git commitされていないファイルがある状態
    branch_status="%F{yellow}!"
  elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
    # コンフリクトが起こった状態
    echo "%F{red}!(no branch)"
    return
  else
    # 上記以外の状態の場合は青色で表示させる
    branch_status="%F{blue}"
  fi
  # ブランチ名を色付きで表示する
  echo "${branch_status}[$branch_name]"
}

# プロンプトが表示されるたびにプロンプト文字列を評価、置換する
setopt prompt_subst

# プロンプトの右側(RPROMPT)にメソッドの結果を表示させる
RPROMPT='`rprompt-git-current-branch`'

# -------------------------------------
# node
# -------------------------------------

# nvm
if [ -e $(brew --prefix nvm)/nvm.sh ]; then
  export NVM_DIR="${HOME}/.nvm"
  source $(brew --prefix nvm)/nvm.sh
fi
