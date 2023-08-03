#!/bin/bash

INSTALL_DIR=$HOME/.config/linux/

set -e

echo "Installing packages..."
sh $INSTALL_DIR/install-packages.sh


if ! command -v rustup &>/dev/null; then
  echo "Installing Rust..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y
else
  echo "Rust is already installed..."
fi

echo "Done!"
