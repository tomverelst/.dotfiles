#!/usr/bin/env bash
# Kill pane. If last pane in last window (and not session 0), kill session and switch to 0.

pane_count=$(tmux list-panes | wc -l | tr -d ' ')
window_count=$(tmux list-windows | wc -l | tr -d ' ')
session=$(tmux display-message -p '#S')

if [[ "$pane_count" -gt 1 ]]; then
    tmux kill-pane
elif [[ "$window_count" -gt 1 ]]; then
    tmux kill-window
elif [[ "$session" != "0" ]]; then
    tmux switch-client -t 0
    tmux kill-session -t "$session"
else
    tmux kill-pane
fi
