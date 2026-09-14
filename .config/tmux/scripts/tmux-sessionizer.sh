#!/usr/bin/env bash
# Fuzzy-find a project directory and create/switch to a tmux session for it.
# Format: "path:depth"

dirs=(
  "$HOME/git/cymo:2"
  "$HOME/git/cymo/kannika:3"
  "$HOME/git/cymo/kp:3"
  "$HOME/git/cruxy:2"
  "$HOME/git/other:2"
  "$HOME/git/tomverelst:2"
  "$HOME/git/kannika:2"
)

# Run all fd searches in parallel, time it, pipe into fzf
start_ns=$(date +%s%N)

results=$(
  {
    for entry in "${dirs[@]}"; do
      dir="${entry%%:*}"
      depth="${entry##*:}"
      if [[ -d "$dir" ]]; then
        fd '^\.git$' "$dir" -HI --min-depth 1 --max-depth "$depth" -x dirname {} 2>/dev/null &
      fi
    done
    wait
  } | sort -u
)

end_ns=$(date +%s%N)
elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
count=$(echo "$results" | grep -c .)

selected=$(echo "$results" | fzf --reverse --prompt="project> " --header="found $count projects in ${elapsed_ms}ms")

if [[ -z $selected ]]; then
    exit 0
fi

name=$(basename "$selected" | tr . _)
# Generic repo names like "main" collide across projects (e.g. kp/0.18/main
# vs kp/0.19/main), so include more of the path to keep sessions distinct.
if [[ $name == main || $name == master ]]; then
    name=$(echo "$selected" | rev | cut -d/ -f1-3 | rev | tr ./ __)
fi

if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -ds "$name" -c "$selected"
fi

# Mirror the session into Herdr so it shows up in the Herdr window too.
~/.config/tmux/scripts/herdr-mirror.sh "$name" "$selected"

tmux switch-client -t "$name"
