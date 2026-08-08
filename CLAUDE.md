# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する個人 dotfiles。テストもビルド成果物もない — 設定を「適用する」ことがそのままビルドに相当する。

複数ホストを 1 リポジトリで管理する。公開するホストは `flake.nix` の `publicHosts`、公開したくないホスト (支給機など) は追跡外の `hosts.local.nix` に置く。

ディレクトリは `hosts/` (ホスト固有のアプリ) / `modules/darwin/` (システム共通部品) / `modules/home/` (ユーザー共通部品) / `home/` (ユーザー組み立て) の 4 区画に分かれる。

## よく使うコマンド

| 用途 | コマンド |
| --- | --- |
| システム + ユーザー設定をまとめて適用 | `sudo darwin-rebuild switch --flake .#<profile>` |
| Home Manager だけ適用 (darwin を触らない) | `nix run home-manager -- switch --flake .#<profile>` |
| 整形 (コミット前に必須 — CI が落ちる) | `nix fmt` |
| flake 出力の検査 | `nix flake check --all-systems --no-build` |
| 構成をビルドだけして確認 | `nix build .#darwinConfigurations.<profile>.system --no-link` |
| flake input を更新 | `nix flake update` → 再 switch (通常は週次の自動 PR に任せる) |
| 一世代前へロールバック | `sudo darwin-rebuild rollback` |

`<profile>` は `personal` / `work`。`hosts.<profile>.hostName` が `scutil --get LocalHostName` と一致していれば省略可。

新規ファイルをツリーに追加した直後に switch する場合は、先に `git add --intent-to-add <file>` を実行する。flake 評価器は git が認識しているファイルしか見ない。

## アーキテクチャ

エントリポイントは `flake.nix`。`hosts` attrset (ホスト名 / system / ユーザー名) を `mkDarwin` に流し込んで `darwinConfigurations` を生成する。出力は:

- `darwinConfigurations.{personal,work}` — 論理名
- `darwinConfigurations."<hostName>"` — 同じ構成への実ホスト名エイリアス (`--flake .` を通すため)
- `formatter.<system>` / `checks.<system>.formatting` — treefmt

### マシン固有の値は `flake.nix` の `hosts` にしか書かない

これが最重要の規約。`modules/` 配下に `/Users/hayato` やホスト名のリテラルを書くと 2 ホスト構成が壊れる。モジュールは `specialArgs` / `extraSpecialArgs` 経由で渡る `host` を参照する:

| フィールド | 例 | 使っている場所 |
| --- | --- | --- |
| `host.username` | `"hayato"` | `modules/darwin/default.nix` の `users.users` / `system.primaryUser` |
| `host.homeDirectory` | `"/Users/hayato"` | `home/default.nix`、`macos-defaults.nix` の screencapture、`git.nix` の ghq.root |
| `host.system` | `"aarch64-darwin"` | `hosts/<profile>/default.nix` の `nixpkgs.hostPlatform` |
| `host.profile` | `"personal"` / `"work"` | ホスト間で分岐したいとき |
| `host.dotfilesPath` | `"/Users/hayato/project/..."` | `nh.nix` の `NH_FLAKE` (未設定なら `null`) |

### 4 層構造 (hosts / modules/darwin / modules/home / home)

ディレクトリの境界は意図的なもので、安易にまたがせない:

- **`hosts/<profile>/`** — そのマシンにしか入れないアプリ。`modules/darwin` を import した上で `nixpkgs.hostPlatform` と差分の `homebrew.casks` / `homebrew.masApps` を載せる。新ホストは `flake.nix` の `hosts` に 1 エントリ + `hosts/<profile>/default.nix` の 2 つだけで足りる。
  - 支給機のプロファイルでは `masApps` を空にしておく — 個人 Apple ID にサインインする前提を置かないため。
- **`modules/darwin/`** — システムスコープの再利用部品。root が必要なものや OS に効く設定。
  - `default.nix`: 共通土台 (homebrew 有効化、fonts、nix experimental-features、`nix.gc` / `nix.optimise`、`users.users.${host.username}` — これが抜けると HM が `home.homeDirectory ... null` で落ちる)。
  - `apps.nix`: **全ホスト共通**の Homebrew cask。
  - `macos-defaults.nix`: `defaults write` の宣言 (Dock / Finder / Screencapture / NSGlobalDomain)。
- **`modules/home/`** — ユーザースコープの再利用部品。CLI ツール / シェル / dotfiles。`default.nix` が兄弟モジュールを全部 import するアグリゲータ。
- **`home/default.nix`** — 組み立て層。`host` から `home.username` / `home.homeDirectory` を受けて `modules/home` を import するだけ。

### Homebrew と Nix の境界

**cask に入れて良いのは GUI アプリ (`.app`) だけ。** CLI は nixpkgs (`modules/home/packages.nix`) か mise (`modules/home/mise.nix`)。

brew が構造的に必要なのは (a) App Store 配布物 (`masApps` — Apple ID にライセンスが紐づき Nix が再配布できない)、(b) `/Library/Input Methods` への pkg インストールが要る入力メソッド (google-japanese-ime)、(c) nixpkgs に無い / darwin 非対応のもの (ghostty, docker-desktop, deepl, cmux, claude)。

nixpkgs に darwin 版が存在する GUI アプリ (chrome, slack, raycast 等) も cask のままにしている。TCC 権限 (アクセシビリティ / 画面収録) がバンドルパスと署名に紐づくため、store path が変わる更新のたびに許可を付け直すことになるのを避けている。

### Sheldon + zsh-defer の組み立て (非自明)

`modules/home/zsh/default.nix` は `programs.sheldon.enableZshIntegration` を **使わない**。代わりに:

1. `programs.zsh.initContent` で `zsh-defer` を最初に source する (`lib.mkBefore`)。後述の `defer` テンプレートが `zsh-defer source ...` を呼ぶため、sheldon の出力が読み込まれる前に zsh-defer コマンドが利用可能になっている必要がある。
2. その上で `sheldon source` を 1 度走らせて `$XDG_CACHE_HOME/sheldon.zsh` に書き出し、`~/.config/sheldon/plugins.toml` が新しい時だけ再生成する。シェル起動ごとの `sheldon source` コストを避けるため。
3. プラグイン (`zsh-autosuggestions` / `zsh-completions` / `zsh-syntax-highlighting`) は `flake = false` の flake input として宣言し、`extraSpecialArgs` 経由で渡す。実行時に取りに行かず Nix store から source する。
4. ローカルプラグインディレクトリは 2 つ — `modules/home/zsh/sync/` (即時 source) と `modules/home/zsh/defer/` (zsh-defer 経由)。スニペットを足す時は適切な側に `.zsh` ファイルを置く。

### モジュール別の注意点

- **Ghostty** (`modules/home/ghostty.nix`): `package = null;` は意図的。nixpkgs の ghostty は `meta.platforms` に darwin を含まない。バイナリは Homebrew cask、HM は設定ファイルだけ書く。
- **LazyVim** (`modules/home/nvim/default.nix`): `lazyvim` flake input (`pfassina/lazyvim-nix`) で管理。**この input は IFD を使う** (`~/.config/nvim` を走査する derivation を `builtins.readFile` する)。そのため darwin 構成は `nix flake check --no-build` では評価できず、`checks` に入れていない。CI は macOS runner で実ビルドして検証する。
- **mise** (`modules/home/mise.nix`) がランタイムと「速く追従したい CLI」を所有する (node / python / claude-code / gemini-cli)。`packages.nix` の `home.packages` に node や python を入れない。
- **git の 2.54 override** (`modules/home/git.nix`): nixpkgs が追いつくまでの暫定。`lib.warnIf` が仕込んであるので、nixpkgs の git が 2.54 以上になると switch 時に警告が出る。それを見たら let ブロックごと削除する。
- **Homebrew cleanup** は `modules/darwin/default.nix` で `"none"` に固定 — 移行期に誤削除を防ぐため意図的にこの値。`"zap"` に変えるとプロファイルに無い cask が一律アンインストールされるので、切り替えは意図を持って行う。
- **Git ignores** (`modules/home/git.nix`) は `**/.claude/settings.local.json` をグローバルに除外している。Claude Code のプロジェクトローカル設定は絶対にコミットしない。

### CI

- `.github/workflows/lint.yaml` — ubuntu で `nix flake check --all-systems --no-build` + フォーマット検査、macOS で `personal` / `work` の実ビルド。
- `.github/workflows/update-flake.yaml` — 毎週月曜に `nix flake update` して PR。

`treefmt.nix` が `nix fmt` の設定。`*.zsh` は除外している (shfmt が zsh 固有構文を壊すため)。

## 編集時の注意

- `home.stateVersion` (`modules/home/default.nix`) と `system.stateVersion` (`modules/darwin/default.nix`) は「最新値に上げる」ものではなく互換性ピン。何も考えずに上げない。
- 新規マシン投入手順とトラブルシュート表は `README.md` / `docs/maintenance.md` にある。セットアップ系の記述を増やす前にそちらを確認する。
