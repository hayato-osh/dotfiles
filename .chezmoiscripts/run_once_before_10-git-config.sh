#!/bin/bash
# Git の初期設定

set -e

echo "🔧 Configuring Git..."

read -p "Enter your Git user name: " git_name
read -p "Enter your Git email: " git_email

git config --global user.name "$git_name"
git config --global user.email "$git_email"

echo "✅ Git configuration complete"
