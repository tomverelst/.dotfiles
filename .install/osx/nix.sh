#!/usr/bin/env bash

# Install Nix package manager

# Check if Nix is already installed
#
set -e

function install-nix() {
 if ! command -v nix-env &> /dev/null; then
    echo "⚙️ Nix is not installed. Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon
    echo "⚙️ Nix installed successfully."
  else
    echo "⚙️ Nix is already installed."
  fi
}


