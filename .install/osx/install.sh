#!/bin/bash

set -e

# Install brew


# Install brew packages
brew install $(cat .brew)

# Install tmux package manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


