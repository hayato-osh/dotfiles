#!/bin/bash
# dotfiles セットアップスクリプト
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayato-osh/dotfiles/main/setup.sh)"

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# macOS チェック
if [[ "$OSTYPE" != "darwin"* ]]; then
    error "このスクリプトは macOS 専用です"
fi

echo "🚀 dotfiles セットアップを開始します..."
echo ""

# 1. Xcode Command Line Tools のインストール
info "Xcode Command Line Tools を確認中..."
if ! xcode-select -p &> /dev/null; then
    info "Xcode Command Line Tools をインストール中..."
    xcode-select --install
    echo ""
    warning "ダイアログで Xcode Command Line Tools のインストールを完了してください"
    warning "インストールが完了したら、Enter キーを押して続行してください..."
    read -r
else
    success "Xcode Command Line Tools は既にインストールされています"
fi

# 2. Homebrew のインストール
info "Homebrew を確認中..."
if ! command -v brew &> /dev/null; then
    info "Homebrew をインストール中..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon の場合は PATH を設定
    if [[ $(uname -m) == "arm64" ]]; then
        info "Apple Silicon 用に Homebrew の PATH を設定中..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    success "Homebrew をインストールしました"
else
    success "Homebrew は既にインストールされています"
fi

# Homebrew PATH の確認
if ! command -v brew &> /dev/null; then
    warning "Homebrew はインストールされていますが PATH に含まれていません。環境を設定中..."
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# 3. chezmoi のインストール
info "chezmoi を確認中..."
if ! command -v chezmoi &> /dev/null; then
    info "chezmoi をインストール中..."
    brew install chezmoi
    success "chezmoi をインストールしました"
else
    success "chezmoi は既にインストールされています"
fi

# 4. dotfiles リポジトリの URL
DOTFILES_REPO="git@github.com:hayato-osh/dotfiles.git"

# SSH 接続可能かチェック
info "GitHub への SSH 接続を確認中..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    success "GitHub への SSH 接続が利用可能です"
    USE_HTTPS=false
else
    warning "GitHub への SSH 接続が利用できません"
    info "代わりに HTTPS を使用します。SSH は後で設定できます。"
    DOTFILES_REPO="https://github.com/hayato-osh/dotfiles.git"
    USE_HTTPS=true
fi

# 5. chezmoi の初期化と適用
echo ""
info "dotfiles を初期化して適用中..."
echo ""
warning "以下の情報の入力を求められます:"
echo "  - Git のユーザー名"
echo "  - Git のメールアドレス"
echo "  - GitHub のメールアドレス (SSH 鍵用)"
echo ""
read -p "Enter キーを押して続行..."

if chezmoi init --apply "$DOTFILES_REPO"; then
    success "dotfiles の適用に成功しました"
else
    error "dotfiles の適用に失敗しました"
fi

# 6. SSH セットアップの案内（HTTPS を使用した場合）
if [[ "$USE_HTTPS" == true ]]; then
    echo ""
    warning "SSH 鍵のセットアップ:"
    echo "  1. セットアップ中に SSH 鍵が生成されました"
    echo "  2. 公開鍵を GitHub に追加してください: https://github.com/settings/keys"
    echo "  3. chezmoi のリモートを SSH に更新してください:"
    echo "     cd ~/.local/share/chezmoi"
    echo "     git remote set-url origin git@github.com:hayato-osh/dotfiles.git"
fi

# 7. 完了メッセージ
echo ""
success "セットアップが完了しました！🎉"
echo ""
info "次のステップ:"
echo "  1. ターミナルを再起動: exec \$SHELL -l"
echo "  2. インストールを確認: chezmoi doctor"
echo ""
info "日常的な使い方:"
echo "  - dotfiles を編集: chezmoi edit ~/.zshrc"
echo "  - 変更を適用: chezmoi apply"
echo "  - リモートから更新: chezmoi update"
echo ""
info "Brewfile にパッケージを追加:"
echo "  - 対話的に追加: brew-add"
echo "  - パッケージを移動: brew-move"
echo "  - Brewfile を同期: brew-sync"
echo ""
