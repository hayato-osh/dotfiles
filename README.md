# dotfiles

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する。

- ホスト固有 (cask / mas) は `hosts/<host>/`
- システムスコープの再利用部品 (`defaults write` / フォント / homebrew 有効化 / nix 設定) は `modules/darwin/`
- ユーザースコープの再利用部品 (CLI / シェル / dotfiles) は `modules/home/`
- ユーザー組み立て (`home.username` などホスト × ユーザーの結合点) は `home/<user>/`
- 1 コマンド (`darwin-rebuild switch`) で全部を反映する

変更を加える時の手引きは [docs/maintenance.md](./docs/maintenance.md)。アーキテクチャの非自明な制約は [CLAUDE.md](./CLAUDE.md)。

## 構成

```
.
├── flake.nix                       # darwinConfigurations の入口
├── hosts/
│   └── HayatonoMacBook-Pro/
│       └── default.nix             # cask + mas + modules/darwin を import
├── modules/
│   ├── darwin/
│   │   ├── default.nix             # homebrew enable / fonts / nix 設定 / users
│   │   └── macos-defaults.nix      # defaults write (Dock / Finder / Screencapture / NSGlobalDomain)
│   └── home/
│       ├── default.nix             # 兄弟モジュールを集約する import-only
│       ├── packages.nix            # nixpkgs の CLI ツール
│       ├── mise.nix                # ランタイム (node / python / gemini-cli)
│       ├── git.nix
│       ├── ghostty.nix             # 設定のみ (バイナリは cask)
│       ├── starship.nix
│       ├── zellij.nix
│       ├── nvim/                   # LazyVim (lazyvim-nix flake input)
│       └── zsh/                    # sheldon + zsh-defer + sync/ defer/
└── home/
    └── hayato/
        └── default.nix             # home.username / home.homeDirectory + modules/home を import
```

## 新規 Mac セットアップ

### 1. Xcode Command Line Tools

```sh
xcode-select --install
```

### 2. Homebrew

cask / mas を引くために `/opt/homebrew/bin/brew` が必要 (nix-darwin が brew bundle を呼ぶため)。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

インストール後、表示される `eval "$(/opt/homebrew/bin/brew shellenv)"` を一度だけ実行 (PATH を通すだけ。永続化は nix-darwin 側に任せる)。

### 3. Nix (Determinate 推奨)

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

新しいシェルを開き直す。

### 4. リポジトリを clone

```sh
mkdir -p ~/project/github.com/hayato-osh
cd ~/project/github.com/hayato-osh
git clone https://github.com/hayato-osh/dotfiles.git
cd dotfiles
```

### 5. SSH 鍵 (GitHub アクセス用)

```sh
ssh-keygen -t ed25519 -C "<メールアドレス>"
cat ~/.ssh/id_ed25519.pub
```

公開鍵を https://github.com/settings/keys に登録。`~/.ssh/config` は宣言化していない (空のまま運用)。GitHub host block 等が必要になったら `modules/home/` に `programs.ssh` モジュールを切り出す ([docs/maintenance.md](./docs/maintenance.md#新しいモジュールを-1-つ切り出す) 参照)。

### 6. ホスト名を `flake.nix` のキーに合わせる

`flake.nix` の `darwinConfigurations.<host>` のキーは `scutil --get LocalHostName` の出力と一致させる必要がある。

```sh
scutil --get LocalHostName
```

ずれていたらどちらかを揃える:

```sh
sudo scutil --set LocalHostName <name>            # マシン側を変える
# または flake.nix のキー名を実機名に書き換える
```

### 7. 初回 switch

`darwin-rebuild` がまだ PATH に無いので `nix run` 経由で 1 度だけ起動する。

```sh
sudo nix run nix-darwin -- switch --flake .
```

衝突する設定ファイル (`~/.zshrc`, `~/.config/zellij/config.kdl`, `~/.config/ghostty/config` など) があれば事前に退避するか、引数で `--backup-extension bk` を付ける。

### 8. 以降は `darwin-rebuild`

```sh
sudo darwin-rebuild switch --flake .
```

### 9. App Store サインイン

`mas` が動くには App Store に Apple ID でサインインしている必要がある。サインインしてから再 switch すると `masApps` が反映される。

### 10. (任意) mise ランタイムの最終確認

`modules/home/mise.nix` で宣言したランタイムが入っているか:

```sh
mise list
```

足りていなければ `mise install` で揃える (config は HM が書いているので edit 不要)。

## 日常運用

| 用途 | コマンド |
| --- | --- |
| cask / mas / system defaults / HM をまとめて反映 | `sudo darwin-rebuild switch --flake .` |
| HM だけ反映 (cask 触ってない時) | `nix run home-manager -- switch --flake .` |
| nixpkgs / lazyvim 等の更新 | `nix flake update && sudo darwin-rebuild switch --flake .` |
| 1 つ前の世代に戻す | `sudo darwin-rebuild rollback` |
| 世代一覧 | `darwin-rebuild --list-generations` |

新しいファイルを追加した直後に switch する時は、先に `git add --intent-to-add <file>` を実行する (flake 評価器は git index に載っているファイルしか見ない)。

変更を加える時の作法 (cask 追加、CLI 追加、mise バージョン上げ、新モジュール切り出し、ホスト追加など) は [docs/maintenance.md](./docs/maintenance.md) に集約してある。
