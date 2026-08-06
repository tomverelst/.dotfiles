#!/usr/bin/env bash
# Run a command in a tmux popup.
# On a narrow client (half-screen terminal) the popup grows to 90%; on a wide
# client it keeps tmux's default 50% so full-screen behaviour is unchanged.

narrow_width=110

size=()
cols=$(tmux display -p '#{client_width}')
if [[ -n $cols && $cols -lt $narrow_width ]]; then
  size=(-w 90% -h 90%)
fi

tmux display-popup -E "${size[@]}" "$@"
