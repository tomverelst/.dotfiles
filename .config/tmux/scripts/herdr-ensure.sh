#!/usr/bin/env bash
# Ensure a Herdr TUI window is open: if no herdr client is running, spawn a
# dedicated Alacritty window running herdr directly (no tmux underneath).
# -g keeps the new window from stealing focus.

if ! ps ax -o command | grep -Eq '(^|/)herdr$'; then
    open -gna Alacritty --args -T herdr -e /opt/homebrew/bin/herdr
fi
