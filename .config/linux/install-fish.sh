#!/bin/bash

set -e

# Install fish
echo "Installing fish..."
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt update
sudo apt install fish


# Install oh my fish
echo "Installing omf..."
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# Install bobthefish theme
echo "Installing bobthefish theme..."
omf install bobthefish

# Install fisher
echo "Installing fisher..."
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# Install z
echo "Installing z..."
fisher install jethrokuan/z

