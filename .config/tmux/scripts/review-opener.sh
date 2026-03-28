#!/usr/bin/env bash
# Find docs/superpowers specs/plans, open in editor popup.

pane_dir=$(tmux display-message -p '#{pane_current_path}')

# Find all docs/superpowers markdown files under pane_dir, sorted by creation time
# Find all superpowers directories, then collect markdown files sorted by creation time
files=$(fd -HI --type d 'superpowers$' "$pane_dir" 2>/dev/null \
  | while read -r sp_dir; do
      fd '\.md$' "$sp_dir" --type f -x stat -f '%B %N' {} 2>/dev/null
    done \
  | sort -rn | cut -d' ' -f2-)

if [[ -z "$files" ]]; then
    tmux display-message "no specs or plans found under $pane_dir"
    exit 0
fi

count=$(echo "$files" | wc -l | tr -d ' ')
selected=$(echo "$files" | fzf-tmux -d20 --reverse --prompt="review> " --header="$count files")

if [[ -z "$selected" ]]; then
    exit 0
fi

tmux display-popup -E -w 90% -h 90% "${EDITOR:-nvim} \"$selected\""
