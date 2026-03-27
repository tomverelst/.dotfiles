#!/usr/bin/env bash
# Extract docs/superpowers paths from tmux pane, select with fzf (last match as default), open in nvim split.

pane_dir=$(tmux display-message -p '#{pane_current_path}')

# Extract matching file paths from the pane
paths=$(tmux capture-pane -J -p \
  | grep -oE 'docs/superpowers/(plans|specs)/[^[:space:]"'"'"']*\.md')

if [[ -z "$paths" ]]; then
    tmux display-message "no docs/superpowers paths found in pane"
    exit 0
fi

# Last match as default (reverse, select first)
selected=$(echo "$paths" | sort -u | tac | fzf-tmux -d20 --reverse --prompt="review> " --select-1)

if [[ -z "$selected" ]]; then
    exit 0
fi

# Resolve to absolute path
filepath="$pane_dir/$selected"

if [[ ! -f "$filepath" ]]; then
    tmux display-message "file not found: $filepath"
    exit 0
fi

# Open in a popup with $EDITOR
tmux display-popup -E -w 90% -h 90% "${EDITOR:-nvim} '$filepath'"
