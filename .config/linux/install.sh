#!/bin/bash

INSTALL_DIR=$HOME/.config/linux/

set -e

# Install packages
echo "Installing packages..."
sh $INSTALL_DIR/install-packages.sh

# Install Rust
if ! command -v rustup &>/dev/null; then
  echo "Installing Rust..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
else
  echo "Rust is already installed..."
fi

if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sh $INSTALL_DIR/install-docker.sh
fi

# Link `batcat` to `bat`
if ! command -v bat &>/dev/null; then
  echo "Linking batcat to bat..."
  mkdir -p ~/.local/bin
  ln -s /usr/bin/batcat ~/.local/bin/bat
fi

# Add ~/.local/bin to $PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo "Adding ~/.local/bin/ to $PATH"
  export PATH="$PATH:$HOME/.local/bin"
fi

echo "Done!"
