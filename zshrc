# ----------------------------------------
# 基本設定
# ----------------------------------------
export LANG=ja_JP.UTF-8
export EDITOR=vim
typeset -U path

# コマンド履歴の設定
HISTFILE=${HOME}/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# 履歴の共有と重複の制御
setopt share_history
setopt hist_ignore_dups
setopt hist_verify

# ディレクトリ操作の簡略化
setopt auto_cd
setopt auto_pushd

# コマンド補完機能の有効化
autoload -Uz compinit && compinit

# ----------------------------------------
# PATH設定
# ----------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

path=( \
  ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin(N-/) \
  ${HOME}/.local/bin \
  $path
)

manpath=( \
  ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman(N-/) \
  $manpath
)

# ----------------------------------------
# 開発環境設定
# ----------------------------------------
# Python (pyenv)
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# direnv
eval "$(direnv hook zsh)"

# zoxide
eval "$(zoxide init zsh)"

# ----------------------------------------
# ツール設定
# ----------------------------------------
# fzf
export FZF_DEFAULT_OPTS='
  --extended
  --ansi
  --multi
  --border
  --reverse
'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ----------------------------------------
# エイリアス
# ----------------------------------------
alias ls="ls --color=auto"
alias ll="ls -la"
alias python="python3"
alias pip="pip3"
alias g='ghq-cd'
alias vi='nvim'
alias vim='nvim'
alias rm='trash'
alias cd='z'
alias cat='bat'

# ----------------------------------------
# カスタム関数
# ----------------------------------------
# ディレクトリ変更時の自動ls実行とiTerm2のタブ名変更
function chpwd() {
  ls
  echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print "/"$1"/"$2}'| rev)\007"
}

# ghqとfzfを使用したリポジトリ移動
function ghq-cd() {
  local repository=$(ghq list | fzf +m)
  [[ -n $repository ]] && cd $(ghq root)/$repository
}

# fzfを使用したhistory検索と実行
function hf() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}
