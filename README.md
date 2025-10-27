# dotfiles

managed by [chezmoi](https://www.chezmoi.io/)

## ディレクトリ構造

```
.
├── .chezmoiroot        # chezmoi のソースルートを home/ に設定
├── .chezmoiscripts/    # chezmoi の自動実行スクリプト
│   ├── run_once_before_10-git-config.sh       # Git 初期設定
│   ├── run_once_before_20-ssh-setup.sh        # SSH 鍵生成
│   ├── run_once_after_30-install-homebrew-bundle.sh  # Homebrew パッケージインストール
│   └── run_once_after_40-macos-defaults.sh    # macOS システム設定
├── home/               # 管理対象の dotfiles
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoiignore
│   ├── dot_bin/        # カスタムコマンド
│   │   ├── executable_brew-add
│   │   ├── executable_brew-move
│   │   └── executable_brew-sync
│   ├── dot_config/     # ~/.config
│   ├── dot_zshrc       # ~/.zshrc
│   ├── dot_tmux.conf   # ~/.tmux.conf
│   ├── dot_asdfrc      # ~/.asdfrc
│   ├── dot_Brewfile.tmpl  # ~/.Brewfile として展開
│   ├── Brewfile.common
│   ├── Brewfile.work
│   └── Brewfile.personal
└── README.md
```

## 初回セットアップ

### ワンライナーでセットアップ（推奨）

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hayato-osh/dotfiles/main/setup.sh)"
```

このコマンドで以下が自動的に実行されます：

1. Xcode Command Line Tools のインストール
2. Homebrew のインストール
3. chezmoi のインストール
4. dotfiles リポジトリのクローン
5. Git 設定（user.name, user.email の入力を求められます）
6. SSH 鍵の生成（GitHub email の入力を求められます）
7. dotfiles の配置
8. Homebrew パッケージのインストール
9. macOS システム設定のカスタマイズ

### 手動セットアップ

#### 1. 事前準備

```bash
# Xcode Command Line Tools のインストール
xcode-select --install

# Homebrew のインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon の場合は PATH を設定
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# chezmoi のインストール
brew install chezmoi
```

#### 2. dotfiles の適用

```bash
chezmoi init --apply git@github.com:hayato-osh/dotfiles.git
```

### 3. セットアップ完了後

```bash
# ターミナルを再起動して設定を反映
exec $SHELL -l
```

## 日常的な使い方

### dotfiles の編集

```bash
# ファイルを編集
chezmoi edit ~/.zshrc

# 変更を確認
chezmoi diff

# 変更を適用
chezmoi apply
```

### 新しいファイルを管理対象に追加

```bash
# ファイルを追加
chezmoi add ~/.gitconfig

# リポジトリにコミット
cd ~/.local/share/chezmoi
git add .
git commit -m "Add .gitconfig"
git push
```

### 他のマシンで同期

```bash
# リモートから最新を取得して適用
chezmoi update
```

## Brewfile 管理

Brewfile は分割管理されており、`dot_Brewfile.tmpl` によって `~/.Brewfile` として統合されます。

### ファイル構成

- **Brewfile.common**: 全マシン共通のパッケージ
- **Brewfile.work**: 会社専用のパッケージ
- **Brewfile.personal**: 個人用のパッケージ

プロファイル設定（work/personal）に応じて、common と work または common と personal が統合され、`~/.Brewfile` として展開されます。

### パッケージの追加

```bash
# 対話型でパッケージを追加（fzf で選択式）
brew-add

# 1. ソースを選択
#    - インストール済み brew パッケージから選択
#    - インストール済み cask パッケージから選択
#    - 手動入力（未インストールのパッケージ用）
# 2. fzf でパッケージを検索・選択
# 3. fzf で追加先を選択（common/work/personal）
```

### パッケージの移動

```bash
# パッケージを別の Brewfile に移動（fzf で選択式）
brew-move

# 1. fzf で移動したいパッケージを検索・選択
# 2. fzf で移動先を選択（common/work/personal）
```

### Brewfile の同期

```bash
# 現在の ~/.Brewfile を chezmoi に反映
brew-sync
```

### ワークフロー例

```bash
# 試しにインストール
brew install foo

# 良さそうなら Brewfile に追加
brew-add
# → インストール済みから選択、または手動入力
# → common/work/personal を選択

# chezmoi に反映して Git にコミット
cd ~/.local/share/chezmoi
git add .
git commit -m "chore: add foo"
git push
```

## macOS システム設定

`run_once_after_40-macos-defaults.sh` で以下の設定が自動的に適用されます：

### Dock
- 自動的に隠す
- アイコンサイズ: 48px
- 最近使った項目を非表示
- 画面下部に配置

### Finder
- 隠しファイルを表示
- パスバーを表示
- ステータスバーを表示
- すべての拡張子を表示
- 拡張子変更時の警告を無効化
- デフォルトビュー: リスト表示

### トラックパッド
- タップでクリックを有効化

### キーボード
- キーリピート速度を高速化
- リピート開始までの時間を短縮
- 長押しでの特殊文字入力を無効化

### スクリーンショット
- 保存先: デスクトップ
- フォーマット: PNG
- 影を無効化

### その他
- 自動大文字変換を無効化
- スマートダッシュを無効化
- ピリオド自動挿入を無効化
- スマートクォートを無効化
- 自動スペルチェックを無効化

設定を変更したい場合は `.chezmoiscripts/run_once_after_40-macos-defaults.sh` を編集してください。

## Tips

- `home/` ディレクトリが実際の dotfiles の配置場所です（`.chezmoiroot` により設定）
- `.chezmoiscripts/` のスクリプトは初回 `chezmoi apply` 時に一度だけ自動実行されます
- chezmoi のテンプレート機能を使って、マシンごとに設定を変えることができます
- `chezmoi doctor` で設定の診断ができます
- Brewfile は分割管理されており、対話型スクリプトで簡単に追加できます
