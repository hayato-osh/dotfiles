#!/bin/bash
# Homebrew パッケージのインストール

set -e

echo "📦 Installing Homebrew packages..."

if [ -f "$HOME/.Brewfile" ]; then
    brew bundle --file="$HOME/.Brewfile"
    echo "✅ Homebrew packages installation complete"
else
    echo "⚠️  Brewfile not found at $HOME/.Brewfile"
    echo "Skipping Homebrew bundle install"
fi
