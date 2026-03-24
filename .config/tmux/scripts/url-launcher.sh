#!/bin/sh
# Extract URLs from tmux pane, select with fzf, open in browser.
# Handles URLs that wrap across terminal lines.
tmux capture-pane -J -p \
  | tr -d '\n' \
  | grep -oE 'https?://[^[:space:]<>"'"'"']*' \
  | fzf-tmux -d20 --multi --bind alt-a:select-all,alt-d:deselect-all \
  | xargs open
