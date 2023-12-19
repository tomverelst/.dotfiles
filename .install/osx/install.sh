#!/bin/bash

set -e

# Install brew
if ! command -v brew &> /dev/null; then
  echo "🍺 Installing brew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "🍺 Updating brew..."
  brew update
fi

# Install brew bundle
echo "🍺 Installing brew bundle..."
brew bundle install

# Install tmux package manager
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "📺 Installing tmux package manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo "📺 Updating tmux package manager..."
  cd ~/.tmux/plugins/tpm && git pull
fi

source ~/.install/osx/krew.sh

if [ ! -f $HOME/.krew/bin/kubectl-krew ]; then
  echo "🐳 Installing krew..."
  install-krew
fi

echo "🐳 Updating krew..."
install-krew-plugins
