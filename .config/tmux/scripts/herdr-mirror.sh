#!/usr/bin/env bash
# Mirror a tmux session into Herdr as a workspace attached to it.
# Usage: herdr-mirror.sh <session-name> <path>

name=$1
path=$2

[[ -z $name || -z $path ]] && exit 1
[[ $name == herdr ]] && exit 0  # never mirror the herdr host session into itself

# Make sure the Herdr window (Alacritty running herdr) is open; starting the
# TUI also boots the server if needed.
~/.config/tmux/scripts/herdr-ensure.sh

if ! herdr workspace list >/dev/null 2>&1; then
    for _ in $(seq 1 50); do
        herdr workspace list >/dev/null 2>&1 && break
        sleep 0.1
    done
    herdr workspace list >/dev/null 2>&1 || exit 0
fi

# Already mirrored?
herdr workspace list | jq -e --arg l "$name" \
    '.result.workspaces[] | select(.label == $l)' >/dev/null && exit 0

resp=$(herdr workspace create --cwd "$path" --label "$name" --no-focus) || exit 0
pane=$(echo "$resp" | jq -r '.result.root_pane.pane_id')
[[ -z $pane || $pane == null ]] && exit 0

herdr pane send-text "$pane" "tmux attach-session -t $name"
herdr pane send-keys "$pane" enter
