#!/usr/bin/env bash
# Find docs/superpowers specs/plans from terminal scrape + filesystem, open in editor popup.

pane_dir=$(tmux display-message -p '#{pane_current_path}')

# Try scraping both normal and alternate screen
scraped=$({
  tmux capture-pane -J -p -S -3000
  tmux capture-pane -J -p -S -3000 -a
} 2>/dev/null \
  | sed 's/^[[:space:]]*//' \
  | tr -s ' ' \
  | grep -oE 'docs/superpowers/(plans|specs)/[^[:space:]"'"'"']*\.md')

# Find docs/superpowers dir by walking up
search_dir="$pane_dir"
superpowers_dir=""
while [[ "$search_dir" != "/" ]]; do
    if [[ -d "$search_dir/docs/superpowers" ]]; then
        superpowers_dir="$search_dir/docs/superpowers"
        break
    fi
    search_dir=$(dirname "$search_dir")
done

# Scan filesystem for files sorted by creation time (newest first)
fs_files=""
if [[ -n "$superpowers_dir" ]]; then
    fs_files=$(fd '\.md$' "$superpowers_dir" --type f -x stat -f '%B %N' {} 2>/dev/null \
      | sort -rn | cut -d' ' -f2- | sed "s|^$search_dir/||")
fi

# Merge: filesystem (sorted by ctime) takes priority, scraped appended, deduplicate preserving order
paths=$(printf '%s\n%s\n' "$fs_files" "$scraped" | grep -v '^$' | awk '!seen[$0]++')

if [[ -z "$paths" ]]; then
    tmux display-message "no specs or plans found"
    exit 0
fi

count=$(echo "$paths" | wc -l | tr -d ' ')
selected=$(echo "$paths" | fzf-tmux -d20 --reverse --tac --prompt="review> " --header="$count files")

if [[ -z "$selected" ]]; then
    exit 0
fi

# Resolve to absolute path, searching up the directory tree
filepath=""
dir="$pane_dir"
while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/$selected" ]]; then
        filepath="$dir/$selected"
        break
    fi
    dir=$(dirname "$dir")
done

if [[ -z "$filepath" ]]; then
    tmux display-message "file not found: $selected"
    exit 0
fi

tmux display-popup -E -w 90% -h 90% "${EDITOR:-nvim} '$filepath'"
