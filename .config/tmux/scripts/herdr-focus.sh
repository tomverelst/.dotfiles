#!/usr/bin/env bash
# Show/focus the Herdr Alacritty window, spawning it first if it isn't running.

~/.config/tmux/scripts/herdr-ensure.sh

# The window may still be launching; wait briefly for the process to appear.
pid=""
for _ in $(seq 1 15); do
    pid=$(pgrep -f "MacOS/alacritty -T herdr" | head -1)
    [[ -n $pid ]] && break
    sleep 0.2
done
[[ -z $pid ]] && exit 1

osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $pid) to true"
