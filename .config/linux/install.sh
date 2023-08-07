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

  echo "Installing cargo-bin..."
  curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

  echo "Installing cargo-watch..."
  cargo binstall --no-confirm cargo-watch
else
  echo "Rust is already installed..."
fi

if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sh $INSTALL_DIR/install-docker.sh
fi

if ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $HOME/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"  
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
