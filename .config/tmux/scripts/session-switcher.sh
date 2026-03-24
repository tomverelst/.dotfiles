#!/bin/sh
# Fuzzy session/window switcher with live pane preview.
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name} (#{pane_current_command})' \
  | fzf-tmux -d20 \
    --preview 'tmux capture-pane -t $(echo {} | cut -d" " -f1) -p' \
    --preview-window=right:60% \
  | cut -d' ' -f1 \
  | xargs tmux switch-client -t
