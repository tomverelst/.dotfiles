#!/usr/bin/env bash
# Run a command in a tmux popup.
# The popup takes a large share of the client, capped in absolute cells so it
# stays readable on a half-screen terminal without swallowing a big monitor.
# Its border is titled with the pane it was opened from, and that pane is
# tinted while the popup is up. Set highlight_style to '' to drop the tint.

pct_w=90
pct_h=90
max_cols=200
max_rows=55
title_format=' #{session_name}:#{window_index}.#{pane_index} #{pane_current_command} '
highlight_style='bg=#45475a'

cols=$(tmux display -p '#{client_width}')
rows=$(tmux display -p '#{client_height}')

size=()
if [[ -n $cols && -n $rows ]]; then
  w=$((cols * pct_w / 100))
  h=$((rows * pct_h / 100))
  if [[ $w -gt $max_cols ]]; then
    w=$max_cols
  fi
  if [[ $h -gt $max_rows ]]; then
    h=$max_rows
  fi
  size=(-w "$w" -h "$h")
fi

pane=${TMUX_PANE:-$(tmux display -p '#{pane_id}')}

unhighlight() {
  if [[ -n $pane ]]; then
    tmux set-option -pu -t "$pane" window-active-style 2>/dev/null
    tmux set-option -pu -t "$pane" window-style 2>/dev/null
  fi
}

if [[ -n $pane && -n $highlight_style ]]; then
  trap unhighlight EXIT
  tmux set-option -p -t "$pane" window-active-style "$highlight_style"
  tmux set-option -p -t "$pane" window-style "$highlight_style"
fi

tmux display-popup -E -T "$title_format" "${size[@]}" "$@"
