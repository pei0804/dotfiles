#!/bin/bash
# Claude Code tmux notification - highlight entire pane on input wait
[ -z "$TMUX" ] && exit 0
[ -z "$TMUX_PANE" ] && exit 0

case "$1" in
  on)
    # Claude is waiting for input - subtle green tint
    # Use set-option -p instead of select-pane to avoid stealing focus
    tmux set-option -p -t "$TMUX_PANE" pane-style 'bg=#11201a'
    ;;
  off)
    # Claude is running - restore default
    tmux set-option -p -t "$TMUX_PANE" -u pane-style
    ;;
esac
