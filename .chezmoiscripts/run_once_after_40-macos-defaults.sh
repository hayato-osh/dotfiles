#!/bin/bash
# macOS システム設定のカスタマイズ

set -e

echo "🖥️  macOS のデフォルト設定を構成しています..."

# ============================================================
# Dock の設定
# ============================================================
echo "Dock を設定しています..."
# Dockを画面の左側に配置する
defaults write com.apple.dock orientation -string "left"
# Dockのアイコンサイズを50ピクセルに設定する
defaults write com.apple.dock tilesize -int 50
# Dockのマウスオーバー時の拡大サイズを80ピクセルに設定する
defaults write com.apple.dock largesize -int 80
# Dockを自動的に隠す
defaults write com.apple.dock autohide -bool true
# Dockに最近使用したアプリケーションを表示しない
defaults write com.apple.dock show-recents -bool false
# ウィンドウ最小化時のエフェクトをジニーエフェクトに設定する
defaults write com.apple.dock mineffect -string "genie"
# 最近使用した順にSpacesを並び替えない（固定順序を維持）
defaults write com.apple.dock mru-spaces -bool false

# ============================================================
# スクリーンショットの設定
# ============================================================
echo "スクリーンショットを設定しています..."
# スクリーンショットの影を無効にする
defaults write com.apple.screencapture disable-shadow -bool true
# スクリーンショットの保存先をデスクトップに設定する
defaults write com.apple.screencapture location -string "${HOME}/Desktop"
# スクリーンショットの形式をPNGに設定する
defaults write com.apple.screencapture type -string "png"

# ============================================================
# Finder の設定
# ============================================================
echo "Finder を設定しています..."
# Finderを終了できるようにする（メニューバーに「Finderを終了」を追加）
defaults write com.apple.finder QuitMenuItem -bool true
# すべての拡張子を表示する
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# パスバーを表示する
defaults write com.apple.finder ShowPathbar -bool true
# フォルダを名前順でソートする際に、常にフォルダを先頭に表示する
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# 検索時のデフォルトスコープを現在のフォルダに設定する
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

# ============================================================
# トラックパッドの設定
# ============================================================
echo "トラックパッドを設定しています..."
# タップでクリックを有効にする
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ============================================================
# テキスト入力と外観の設定
# ============================================================
echo "テキスト入力と外観を設定しています..."
# 自動大文字変換を無効にする
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
# スマートダッシュ記号を無効にする（--を—に変換しない）
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
# スマートピリオドを無効にする（スペース2回で.に変換しない）
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# スマート引用符を無効にする（"を"に変換しない）
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
# 自動スペルチェックを無効にする
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
# ダークモードを有効にする
defaults write -g AppleInterfaceStyle -string "Dark"

# ============================================================
# 変更を反映
# ============================================================
echo "影響を受けるアプリケーションを再起動しています..."
# Dockを再起動して設定を反映する
killall Dock 2>/dev/null || true
# Finderを再起動して設定を反映する
killall Finder 2>/dev/null || true
# システムUIサーバーを再起動して設定を反映する
killall SystemUIServer 2>/dev/null || true

echo "✅ macOS のデフォルト設定が完了しました"
echo "注意: 一部の変更はシステム再起動後に完全に反映されます。"
