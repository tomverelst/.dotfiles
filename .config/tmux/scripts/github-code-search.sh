#!/usr/bin/env bash
# GitHub code search → pick org → live card search → clone repo and open tmux session.

declare -A org_dir=(
  [cymo-eu]="$HOME/git/cymo"
  [cruxy-eu]="$HOME/git/cruxy"
  [tomverelst]="$HOME/git/tomverelst"
  [kannika-io]="$HOME/git/kannika"
)

orgs=("cymo-eu" "cruxy-eu" "tomverelst" "kannika-io")

# Step 1: pick org
org=$(printf '%s\n' "${orgs[@]}" | fzf --reverse --prompt="org> " --header="select organisation")
[[ -z "$org" ]] && exit 0

# Helper script for async reload — outputs null-separated multi-line cards
search_script=$(mktemp /tmp/gh-search-XXXXXX.sh)
chmod +x "$search_script"
cat > "$search_script" << 'EOF'
#!/usr/bin/env bash
query="$1"
org="$2"
[[ -z "$query" ]] && exit 0

gh search code "$query" --owner "$org" --json repository,path,textMatches --limit 30 2>/dev/null \
  | jq -rj '.[] |
      .repository.nameWithOwner as $repo |
      .path as $path |
      (.textMatches // [{}])[0].fragment as $frag |
      # Card: bold cyan repo, dim path, indented snippet, null-terminated
      "\u001b[1;36m" + $repo + "\u001b[0m  \u001b[2m" + $path + "\u001b[0m\n" +
      ($frag // ""
        | split("\n")
        | map(select(length > 0))
        | map("  \u001b[2m" + . + "\u001b[0m")
        | .[0:5]
        | join("\n")
      ) + "\u0000"'
EOF

# Step 2: live card search — multi-line items, no preview pane needed
selected=$(
  </dev/null fzf --reverse \
      --prompt="[$org] > " \
      --header="type to search code in $org" \
      --disabled \
      --ansi \
      --read0 \
      --gap \
      --bind "change:reload($search_script {q} $org)"
)

rm -f "$search_script"
[[ -z "$selected" ]] && exit 0

# Extract repo from first line (strip ANSI codes)
first_line=$(echo "$selected" | head -1 | sed 's/\x1b\[[0-9;]*m//g')
repo_full=$(echo "$first_line" | awk '{print $1}')
org="${repo_full%%/*}"
repo="${repo_full##*/}"
target_dir="${org_dir[$org]}/$repo"

if [[ -z "${org_dir[$org]}" ]]; then
    tmux display-message "unknown org: $org"
    exit 0
fi

worktree_dir="$target_dir/main"

if [[ -d "$target_dir" ]]; then
    tmux display-message "already cloned: $target_dir"
else
    confirmed_dir=$(echo "$target_dir" | fzf --reverse --print-query --prompt="clone to> " --header="$repo_full" | tail -1)
    [[ -z "$confirmed_dir" ]] && exit 0

    target_dir="$confirmed_dir"
    worktree_dir="$target_dir/main"
    mkdir -p "$target_dir"
    git clone --bare "git@github.com:$repo_full.git" "$target_dir/.bare"
    echo "gitdir: ./.bare" > "$target_dir/.git"
    git -C "$target_dir" worktree add main
fi

if [[ -d "$worktree_dir" ]]; then
    session_dir="$worktree_dir"
else
    session_dir="$target_dir"
fi

name=$(basename "$target_dir" | tr . _)

if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -ds "$name" -c "$session_dir"
fi

tmux switch-client -t "$name"
