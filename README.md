# dotfiles

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する。

- マシン固有の値 (ホスト名 / ユーザー名) は `flake.nix` の `hosts` attrset に集約
- git の identity だけは追跡外の `~/.config/git/local.conf` (public リポジトリにメールアドレスを載せないため)
- ホスト固有のアプリ (cask / mas) は `hosts/<profile>/`
- システムスコープの再利用部品 (`defaults write` / フォント / 共通 cask / nix 設定) は `modules/darwin/`
- ユーザースコープの再利用部品 (CLI / シェル / dotfiles) は `modules/home/`
- 1 コマンド (`darwin-rebuild switch`) で全部を反映する

変更を加える時の手引きは [docs/maintenance.md](./docs/maintenance.md)。アーキテクチャの非自明な制約は [CLAUDE.md](./CLAUDE.md)。

## ホスト

| プロファイル | 用途 | ユーザー | switch コマンド |
| --- | --- | --- | --- |
| `personal` | 個人 MacBook Pro | `hayato` | `sudo darwin-rebuild switch --flake .#personal` |

`flake.nix` の `publicHosts.<profile>.hostName` が `scutil --get LocalHostName` と一致していれば、プロファイル名を省いて `--flake .` だけでも通る。

### 公開したくないホスト

支給機など、ホスト名やアカウント名を公開したくないマシンは**このリポジトリにコミットしない**。追跡外の 2 ファイルに置く:

```
hosts.local.nix          # プロファイル定義 (hostName / system / username)
hosts/<profile>/         # そのホスト固有の cask / mas
```

どちらも `.gitignore` 済みなので push しても中身は出ない。flake は git が追跡しているファイルしか読まないため、`--flake .` からは**見えない**。読ませるマシンでは `path:` 参照を使う:

```sh
sudo darwin-rebuild switch --flake path:.#<profile>
```

`path:` は git の追跡状態を無視してディレクトリ全体を読むので、追跡外ファイルが評価対象に入る。公開リポジトリと CI からは `personal` しか見えないまま。

## 構成

```
.
├── flake.nix                       # hosts 定義 + darwinConfigurations / formatter / checks
├── treefmt.nix                     # nix fmt の設定 (nixfmt + yamlfmt)
├── hosts/
│   └── personal/default.nix        # 個人機だけの cask + mas
│                                   # (公開しないホストの hosts/<profile>/ は追跡外)
├── modules/
│   ├── darwin/
│   │   ├── default.nix             # homebrew enable / fonts / nix 設定 / gc / users
│   │   ├── apps.nix                # 全ホスト共通の cask
│   │   └── macos-defaults.nix      # defaults write (Dock / Finder / Screencapture / NSGlobalDomain)
│   └── home/
│       ├── default.nix             # 兄弟モジュールを集約する import-only
│       ├── packages.nix            # nixpkgs の CLI ツール
│       ├── mise.nix                # ランタイム (node / python / claude-code / gemini-cli)
│       ├── git.nix
│       ├── ghostty.nix             # 設定のみ (バイナリは cask)
│       ├── starship.nix
│       ├── nvim/                   # LazyVim (lazyvim-nix flake input)
│       └── zsh/                    # sheldon + zsh-defer + sync/ defer/
├── home/
│   └── default.nix                 # home.username / homeDirectory を host から受けて modules/home を import
└── .github/workflows/              # lint (fmt + flake check + darwin build) / update-flake (週次 PR)
```

`modules/` 配下にユーザー名やホームディレクトリのリテラルは書かない。すべて `host` 経由で流れてくる。

## 新規 Mac セットアップ

どのマシンでも同じ手順。`<profile>` は公開ホストなら `personal`、追跡外ホストなら `hosts.local.nix` で定義した名前。

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

### 3. Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

新しいシェルを開き直す。

> `--determinate` を **付けない**こと。Determinate Nix を入れると `/etc/nix/nix.conf` の所有権が nix-darwin と衝突し、`nix.enable = false;` が必要になる。この構成は nix-darwin に nix.conf を管理させている (`modules/darwin/default.nix` の `nix.settings` / `nix.gc`)。

### 4. リポジトリを clone

```sh
mkdir -p ~/project/github.com/hayato-osh
cd ~/project/github.com/hayato-osh
git clone https://github.com/hayato-osh/dotfiles.git
cd dotfiles
```

### 5. `flake.nix` の `hosts` を実機に合わせる

そのマシンの値を確認する:

```sh
scutil --get LocalHostName
whoami
```

`flake.nix` の該当プロファイルの `hostName` / `username` が実機と合っているか見る。合っていなければ書き換える (`hostName` はズレていても `--flake .#<profile>` で回避できるが、揃えたほうが楽)。

### 6. git の identity を置く

**このリポジトリは `user.name` / `user.email` を宣言していない。** public リポジトリにメールアドレスを載せないため、追跡外のファイルに追い出してある。マシンごとに 1 回だけ作る:

```sh
mkdir -p ~/.config/git
cat > ~/.config/git/local.conf <<'EOF'
[user]
	name = <名前>
	email = <そのマシンで使うメールアドレス>
EOF
```

HM が書き出す `~/.config/git/config` の末尾からこのファイルを include している。作り忘れると最初のコミットで `Please tell me who you are` が出る (意図した挙動 — 意図しないアドレスで黙ってコミットされるより落ちたほうが良い)。

### 7. SSH 鍵 (GitHub アクセス用)

```sh
ssh-keygen -t ed25519 -C "<メールアドレス>"
cat ~/.ssh/id_ed25519.pub
```

公開鍵を https://github.com/settings/keys に登録。`~/.ssh/config` は宣言化していない (空のまま運用)。GitHub host block 等が必要になったら `modules/home/` に `programs.ssh` モジュールを切り出す ([docs/maintenance.md](./docs/maintenance.md#新しいモジュールを-1-つ切り出す) 参照)。

### 8. 初回 switch

`darwin-rebuild` がまだ PATH に無いので `nix run` 経由で 1 度だけ起動する。

```sh
sudo nix run nix-darwin -- switch --flake .#<profile>
```

衝突する設定ファイル (`~/.zshrc`, `~/.config/ghostty/config` など) があれば事前に退避するか、引数で `--backup-extension bk` を付ける。

### 9. 以降は `darwin-rebuild`

```sh
sudo darwin-rebuild switch --flake .#<profile>
```

### 10. App Store サインイン (個人機のみ)

`mas` が動くには App Store に Apple ID でサインインしている必要がある。サインインしてから再 switch すると `masApps` が反映される。

支給機のプロファイルでは `masApps` を空にしておくとよい。個人 Apple ID でのサインインを前提に置かないため。必要になったら `hosts/personal/default.nix` からコピーして足す。

### 11. (任意) mise ランタイムの最終確認

`modules/home/mise.nix` で宣言したランタイムが入っているか:

```sh
mise list
```

足りていなければ `mise install` で揃える (config は HM が書いているので edit 不要)。

## 日常運用

| 用途 | コマンド |
| --- | --- |
| cask / mas / system defaults / HM をまとめて反映 | `sudo darwin-rebuild switch --flake .#<profile>` |
| HM だけ反映 (cask 触ってない時) | `nix run home-manager -- switch --flake .#<profile>` |
| 整形 (コミット前) | `nix fmt` |
| flake 出力の検査 | `nix flake check --all-systems --no-build` |
| 構成をビルドだけして確認 | `nix build .#darwinConfigurations.<profile>.system --no-link` |
| nixpkgs / lazyvim 等の更新 | 週次の自動 PR をマージ → switch (手動なら `nix flake update`) |
| 1 つ前の世代に戻す | `sudo darwin-rebuild rollback` |
| 世代一覧 | `darwin-rebuild --list-generations` |

新しいファイルを追加した直後に switch する時は、先に `git add --intent-to-add <file>` を実行する (flake 評価器は git index に載っているファイルしか見ない)。

## パッケージの入り口 (どこに何を足すか)

| 種類 | 行き先 |
| --- | --- |
| GUI アプリ (全ホスト共通) | `modules/darwin/apps.nix` の `homebrew.casks` |
| GUI アプリ (片方だけ) | `hosts/<profile>/default.nix` の `homebrew.casks` |
| App Store アプリ | `hosts/<profile>/default.nix` の `homebrew.masApps` |
| CLI ツール | `modules/home/packages.nix` |
| バージョンを切り替えたいランタイム / 速く追従したい CLI | `modules/home/mise.nix` |

**Homebrew は GUI アプリ専用**。cask に CLI を入れない (`1password-cli` や `claude-code` のような CLI 専用 cask は nixpkgs / mise 側に置く)。

## CI

| workflow | runner | 内容 |
| --- | --- | --- |
| `lint.yaml` / `lint` | ubuntu | `nix flake check` + フォーマット検査 |
| `lint.yaml` / `build-darwin` | macOS | `personal` の構成を実ビルド (追跡外ホストは checkout に含まれないので対象外) |
| `update-flake.yaml` | ubuntu | 毎週月曜に `nix flake update` して PR |

`update-flake.yaml` が PR を作れるようにするには、Settings → Actions → General で **Allow GitHub Actions to create and approve pull requests** を有効にする。

変更を加える時の作法 (cask 追加、CLI 追加、mise バージョン上げ、新モジュール切り出し、ホスト追加など) は [docs/maintenance.md](./docs/maintenance.md) に集約してある。
