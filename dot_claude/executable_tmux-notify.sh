#!/bin/bash
# Claude Code tmux notification - highlight entire pane on input wait
[ -z "$TMUX" ] && exit 0
[ -z "$TMUX_PANE" ] && exit 0

case "$1" in
  on)
    # Claude is waiting for input - subtle green tint
    tmux select-pane -t "$TMUX_PANE" -P 'bg=#11201a'
    ;;
  off)
    # Claude is running - restore default
    tmux select-pane -t "$TMUX_PANE" -P 'default'
    ;;
esac
