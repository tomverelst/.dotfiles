#!/usr/bin/env bash
# Fuzzy-find a project directory and create/switch to a tmux session for it.
# Format: "path:depth"

dirs=(
  "$HOME/git/cymo:2"
  "$HOME/git/cymo/k:3"
  "$HOME/git/cymo/kp:3"
  "$HOME/git/cruxy:2"
  "$HOME/git/other:2"
  "$HOME/git/tomverelst:2"
)

results=""
for entry in "${dirs[@]}"; do
  dir="${entry%%:*}"
  depth="${entry##*:}"
  if [[ -d "$dir" ]]; then
    # Find regular repos (.git dir) and worktree checkouts (.git file)
    found=$(find "$dir" -mindepth 1 -maxdepth "$depth" -name .git -exec dirname {} \; 2>/dev/null)
    results+="$found"$'\n'
  fi
done

selected=$(echo "$results" | grep -v '^$' | sort -u | fzf --reverse --prompt="project> ")

if [[ -z $selected ]]; then
    exit 0
fi

name=$(basename "$selected" | tr . _)

if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -ds "$name" -c "$selected"
fi

tmux switch-client -t "$name"
