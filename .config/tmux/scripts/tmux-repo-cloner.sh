#!/usr/bin/env bash
# Fuzzy-find a GitHub repo and clone it into the matching local directory.

declare -A org_dir=(
  [cymo-eu]="$HOME/git/cymo"
  [cruxy-eu]="$HOME/git/cruxy"
  [tomverelst]="$HOME/git/tomverelst"
  [kannika-io]="$HOME/git/kannika"
)

orgs=("cymo-eu" "cruxy-eu" "tomverelst" "kannika-io")

start_ns=$(date +%s%N)

# Fetch repos from all orgs in parallel
repos=$(
  {
    for org in "${orgs[@]}"; do
      gh repo list "$org" --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' 2>/dev/null &
    done
    wait
  } | sort -u
)

end_ns=$(date +%s%N)
elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
count=$(echo "$repos" | grep -c .)

selected=$(echo "$repos" | fzf --reverse --prompt="clone> " --header="found $count repos in ${elapsed_ms}ms")

if [[ -z $selected ]]; then
    exit 0
fi

org="${selected%%/*}"
repo="${selected##*/}"
target_dir="${org_dir[$org]}/$repo"

worktree_dir="$target_dir/main"

if [[ -d "$target_dir" ]]; then
    tmux display-message "already cloned: $target_dir"
else
    # Confirm clone target (editable)
    target_dir=$(echo "$target_dir" | fzf --reverse --print-query --prompt="clone to> " --header="$selected" | tail -1)

    if [[ -z $target_dir ]]; then
        exit 0
    fi

    worktree_dir="$target_dir/main"
    mkdir -p "$target_dir"
    git clone --bare "git@github.com:$selected.git" "$target_dir/.bare"
    echo "gitdir: ./.bare" > "$target_dir/.git"
    git -C "$target_dir" worktree add main
fi

# Use worktree dir if it exists, otherwise the repo dir itself
if [[ -d "$worktree_dir" ]]; then
    session_dir="$worktree_dir"
else
    session_dir="$target_dir"
fi

# Create/switch to tmux session for the repo
name=$(basename "$target_dir" | tr . _)

if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -ds "$name" -c "$session_dir"
fi

tmux switch-client -t "$name"
