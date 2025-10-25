#!/bin/bash
# SSH 鍵の生成

set -e

echo "🔐 Setting up SSH keys..."

read -p "Enter your GitHub email address: " github_email

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_rsa"

if [ -f "$SSH_KEY" ]; then
    echo "⚠️  SSH key already exists at $SSH_KEY"
    read -p "Do you want to create a new one? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "Skipping SSH key generation"
        exit 0
    fi
fi

mkdir -p "$SSH_DIR"
ssh-keygen -t rsa -C "$github_email" -f "$SSH_KEY"
chmod 600 "$SSH_KEY"

echo ""
echo "✅ SSH key generated successfully"
echo "📋 Your public key:"
echo ""
cat "$SSH_KEY.pub"
echo ""
echo "Please add this key to your GitHub account:"
echo "https://github.com/settings/keys"
