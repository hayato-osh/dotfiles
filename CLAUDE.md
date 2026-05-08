# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する個人 dotfiles。テストもビルド成果物もない — 設定を「適用する」ことがそのままビルドに相当する。

## よく使うコマンド

| 用途 | コマンド |
| --- | --- |
| システム + ユーザー設定をまとめて適用 (cask / mas / system defaults / HM) | `sudo darwin-rebuild switch --flake .` |
| Home Manager だけ適用 (darwin を触らない) | `nix run home-manager -- switch --flake .` |
| flake input (nixpkgs / lazyvim / sheldon プラグイン) を更新 | `nix flake update` → 再 switch |
| 一世代前へロールバック | `sudo darwin-rebuild rollback` |
| 世代一覧 | `darwin-rebuild --list-generations` |

新規ファイルをツリーに追加した直後に switch する場合は、先に `git add --intent-to-add <file>` を実行する。flake 評価器は git が認識しているファイルしか見ない。

## アーキテクチャ

エントリポイントは `flake.nix`。出力は 2 つ:

- `darwinConfigurations."HayatonoMacBook-Pro"` — 実運用経路。`darwin/default.nix` + プロファイル + `home-manager.darwinModules.home-manager` を組み合わせ、HM を darwin activation の中で走らせる。
- `homeConfigurations."hayato@HayatonoMacBook-Pro.local"` — nix-darwin を使わずに HM 単独で switch できる互換経路として残してある。

flake のキー (`HayatonoMacBook-Pro`) は **`scutil --get LocalHostName` の出力と一致させる必要がある**。ずれていると `darwin-rebuild` が `darwinConfigurations.<host>.system not found` で落ちる。

### 2 層構造 (darwin / home-manager)

`darwin/` と `home-manager/` の境界は意図的なもので、安易にまたがせない:

- **`darwin/`** — システムスコープ。root が必要なものや OS に効く設定: `homebrew.casks`、`homebrew.masApps`、`system.defaults` (= `defaults write`)、`fonts.packages`、`users.users.<name>`、nix デーモン設定。
  - `darwin/default.nix`: 共通土台 (homebrew 有効化、fonts、nix experimental-features、`users.users.hayato` の name + home — これが抜けると HM が `home.homeDirectory ... null` で落ちる)。
  - `darwin/macos-defaults.nix`: `defaults write` の宣言 (Dock / Finder / Screencapture / NSGlobalDomain)。
  - `darwin/profiles/<name>.nix`: ホスト単位の cask / mas リスト。現状は `personal.nix` のみ。work マシン追加時は `personal.nix` を雛形に `work.nix` を作り、`flake.nix` に `darwinConfigurations."<work-host>"` を 1 エントリ足してプロファイルだけ差し替える。
- **`home-manager/home/`** — ユーザースコープ。CLI ツール / シェル / dotfiles。`common.nix` が他の兄弟モジュールを全部 import するアグリゲータ。`mac.nix` で `home.username` / `home.homeDirectory` を設定。両方とも `flake.nix` の `hmCommonModules` に並ぶ。

### Sheldon + zsh-defer の組み立て (非自明)

`home-manager/home/zsh/default.nix` は `programs.sheldon.enableZshIntegration` を **使わない**。代わりに:

1. `programs.zsh.initContent` で `zsh-defer` を最初に source する (`lib.mkBefore`)。後述の `defer` テンプレートが `zsh-defer source ...` を呼ぶため、sheldon の出力が読み込まれる前に zsh-defer コマンドが利用可能になっている必要がある。
2. その上で `sheldon source` を 1 度走らせて `$XDG_CACHE_HOME/sheldon.zsh` に書き出し、`~/.config/sheldon/plugins.toml` が新しい時だけ再生成する。シェル起動ごとの `sheldon source` コストを避けるため。
3. プラグイン (`zsh-autosuggestions` / `zsh-completions` / `zsh-syntax-highlighting`) は `flake = false` の flake input として宣言し、`extraSpecialArgs` 経由で渡す。実行時に取りに行かず Nix store から source する。
4. ローカルプラグインディレクトリは 2 つ — `home-manager/home/zsh/sync/` (即時 source) と `home-manager/home/zsh/defer/` (zsh-defer 経由)。スニペットを足す時は適切な側に `.zsh` ファイルを置く。

### モジュール別の注意点

- **Ghostty** (`ghostty.nix`): `package = null;` は意図的。バイナリは Homebrew cask (`darwin/profiles/personal.nix`) から入れ、HM は設定ファイルだけ書く。macOS では HM 側のパッケージを有効化しない。
- **LazyVim** (`nvim/default.nix`): `lazyvim` flake input (`pfassina/lazyvim-nix`) で管理。`installCoreDependencies = true` で ripgrep / fd 等の前提依存をまとめて入れる。プラグインの override は Nix の中にインライン Lua 文字列で書く。
- **mise** (`mise.nix`) がランタイムバージョン (node / python / gemini-cli) を所有する。`packages.nix` の `home.packages` に node や python を入れない — それは mise の領分。`packages.nix` はプロジェクト単位のバージョン切り替えが不要なツール用。
- **Homebrew cleanup** は `darwin/default.nix` で `"none"` に固定 — 移行期に誤削除を防ぐため意図的にこの値。`"zap"` に変えるとプロファイルに無い cask が一律アンインストールされるので、切り替えは意図を持って行う。
- **Git ignores** (`git.nix`) は `**/.claude/settings.local.json` をグローバルに除外している。Claude Code のプロジェクトローカル設定は絶対にコミットしない。

## 編集時の注意

- `home.stateVersion` (`common.nix`) と `system.stateVersion` (`darwin/default.nix`) は「最新値に上げる」ものではなく互換性ピン。何も考えずに上げない。
- 新規マシン投入手順とトラブルシュート表は `README.md` にある。セットアップ系の記述を増やす前にそちらを確認する。
