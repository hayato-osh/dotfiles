---
name: dotfiles-maintenance
description: Nix Flake + nix-darwin + Home Manager で管理する macOS dotfiles リポを編集・更新・トラブルシュートするとき。`hosts/`、`modules/`、`home/`、`flake.nix` 配下の編集、Homebrew cask / mas アプリ / nixpkgs CLI / mise ランタイム / `defaults write` / zsh スニペット / LazyVim 設定 / 新ホスト追加 / `nix flake update` / `darwin-rebuild switch` の失敗対応で発火。トリガー語例 - 「cask 追加」「brew で入れたい」「mise の node を上げる」「macOS の dock を」「zsh のエイリアス」「新しい mac のセットアップ」「flake update」「switch が落ちる」。一時的なツール導入や 1 プロジェクト用の依存追加では使わない (代わりに `nix shell` / プロジェクトローカル `flake.nix` / `mise use`)。
---

# dotfiles メンテナンス

## 概要

このリポジトリは macOS 環境を宣言的に管理する (Nix Flake + nix-darwin + Home Manager)。すべての変更は `.nix` ファイルへの編集として行い、`sudo darwin-rebuild switch --flake .` で適用する。命令的な「とりあえずインストール」ステップは存在しない。

詳細レシピは [docs/maintenance.md](../../../docs/maintenance.md) に集約してあるので、本 skill ではルーティング判断・厳守ルール・典型的な差分・該当ドキュメントへのポインタだけを持つ。

## ルーティング: 何をどこに足すか

| ユーザーが追加・変更したいもの | 編集先 | 詳細レシピ |
| --- | --- | --- |
| GUI アプリ (App Store 以外) | [`hosts/HayatonoMacBook-Pro/default.nix`](../../../hosts/HayatonoMacBook-Pro/default.nix) の `homebrew.casks` | [Homebrew cask を 1 つ足す](../../../docs/maintenance.md#homebrew-cask-を-1-つ足す) |
| App Store のアプリ | [`hosts/HayatonoMacBook-Pro/default.nix`](../../../hosts/HayatonoMacBook-Pro/default.nix) の `homebrew.masApps` | [App Store アプリを足す (mas)](../../../docs/maintenance.md#app-store-アプリを足す-mas) |
| CLI ツール (プロジェクト単位のバージョン切替不要) | [`modules/home/packages.nix`](../../../modules/home/packages.nix) の `let` バインディング | [CLI ツール (nixpkgs) を足す](../../../docs/maintenance.md#cli-ツール-nixpkgs-を足す) |
| プロジェクト単位でバージョン切替するランタイム (node / python / ruby など) | [`modules/home/mise.nix:9`](../../../modules/home/mise.nix) の `globalConfig.tools` | [mise でランタイムを増やす / バージョンを上げる](../../../docs/maintenance.md#mise-でランタイムを増やす--バージョンを上げる) |
| フォント | [`modules/darwin/default.nix`](../../../modules/darwin/default.nix) の `fonts.packages` | (packages.nix のパターンを踏襲) |
| `defaults write` (Dock / Finder / NSGlobalDomain 等) | [`modules/darwin/macos-defaults.nix`](../../../modules/darwin/macos-defaults.nix) | [macOS の `defaults write` を足す](../../../docs/maintenance.md#macos-の-defaults-write-を足す) |
| zsh スニペット — 即時 source (PATH / options 系) | `modules/home/zsh/sync/<name>.zsh` を新規作成 | [zsh のエイリアスや関数を足す](../../../docs/maintenance.md#zsh-のエイリアスや関数を足す) |
| zsh スニペット — 遅延 source (alias / 補完 / fzf glue) | `modules/home/zsh/defer/<name>.zsh` を新規作成 | 同上 |
| ツール固有設定 (git / zellij / starship / ghostty) | `modules/home/<tool>.nix` の `programs.<tool>.settings` | [git の global ignore を足す](../../../docs/maintenance.md#git-の-global-ignore-を足す) ほか |
| Neovim プラグイン override / colorscheme | [`modules/home/nvim/default.nix`](../../../modules/home/nvim/default.nix) の `plugins.overrides` (Lua 文字列) | [Neovim (LazyVim) のプラグインを上書き / 追加](../../../docs/maintenance.md#neovim-lazyvim-のプラグインを上書き--追加) |
| 新規 HM モジュール (例: `programs.ssh`) | `modules/home/<name>.nix` 新規 + [`modules/home/default.nix`](../../../modules/home/default.nix) の `imports` に追加 | [新しいモジュールを 1 つ切り出す](../../../docs/maintenance.md#新しいモジュールを-1-つ切り出す) |
| 新ホスト (work mac 等) | `hosts/<host>/default.nix` を新規 + [`flake.nix`](../../../flake.nix) に `darwinConfigurations` エントリ追加 | [新ホスト追加](../../../docs/maintenance.md#新ホスト追加-work-マシン等) |
| input 更新 (nixpkgs / lazyvim / sheldon プラグイン) | `nix flake update [<input>]` で `flake.lock` を更新 | [更新作業](../../../docs/maintenance.md#更新作業) |

ユーザーの依頼が表に当てはまらない場合は、行動する前に [docs/maintenance.md](../../../docs/maintenance.md) を全文読む。skill 本体が要約で落としたケースの可能性がある。

## 典型的な差分例 (ルーティング → 実差分の橋渡し)

### 例 1: 「Rectangle (cask) を入れて」

`hosts/HayatonoMacBook-Pro/default.nix` の `casks` (アルファベット順) に 1 行追加:

```diff
   "postman"
   "raycast"
+  "rectangle"
   "slack"
```

その後 `sudo darwin-rebuild switch --flake .`。

### 例 2: 「mise の node を 22.18.0 に上げて」

[`modules/home/mise.nix:9`](../../../modules/home/mise.nix) の `globalConfig.tools.node` を書き換え:

```diff
       tools = {
-        node = "22.17.0";
+        node = "22.18.0";
         "npm:@google/gemini-cli" = "latest";
         python = "latest";
       };
```

その後 `sudo darwin-rebuild switch --flake .`。`mise install` を別途打つ必要は無い (HM が `~/.config/mise/config.toml` を書き出すと mise が次回起動時に自動取得)。

### 例 3: 「zsh で `ll` エイリアスを足して (起動が遅くなるのは嫌)」

`modules/home/zsh/defer/<name>.zsh` を新規作成 (遅延 source なので `defer/` 側):

```sh
alias ll='eza -l --git'
```

新規ファイルは [`git add --intent-to-add`](../../../docs/maintenance.md#大原則) しないと flake が認識しない。その後 switch + 新シェルで確認。

## 厳守ルール (過去にユーザーが踏んだ罠)

1. **新規ファイルを作ったら switch 前に必ず `git add --intent-to-add <file>`**。Nix の flake 評価器は git index に載っているファイルしか見ない。これを忘れると意味のわからない「ファイルが見つからない」エラーが出る。
2. **層の境界をまたがない**。`hosts/` + `modules/darwin/` = root/OS スコープ・cask・mas・`defaults write`・フォント・users。`modules/home/` + `home/` = ユーザースコープの CLI と dotfiles。HM に cask を入れたり、darwin に CLI ツールを入れたりするのは「層を間違えている」サイン。
3. **ランタイムは mise の領分** ([`modules/home/mise.nix:9`](../../../modules/home/mise.nix))。`nodejs`、`python`、`ruby`、`go` 等を [`modules/home/packages.nix`](../../../modules/home/packages.nix) に入れない。
4. **`programs.ghostty.package = null;` は意図的** ([`modules/home/ghostty.nix:7`](../../../modules/home/ghostty.nix))。バイナリは Homebrew cask、HM は設定ファイルだけ書く。`package = null;` を「直そう」として消さない。
5. **Sheldon 統合は手動配線** ([`modules/home/zsh/default.nix:11`](../../../modules/home/zsh/default.nix) の `lib.mkBefore` ブロックと [`:31`](../../../modules/home/zsh/default.nix) の `enableZshIntegration = false;` は 1 セット)。zsh-defer を sheldon キャッシュより先に source する必要があるため。手動キャッシュコードを残したまま `enableZshIntegration` を `true` に切り替えない。
6. **`home.stateVersion`** ([`modules/home/default.nix:22`](../../../modules/home/default.nix)) **と `system.stateVersion`** ([`modules/darwin/default.nix:13`](../../../modules/darwin/default.nix)) **は互換性ピン**。Home Manager や nix-darwin が新リリースを出したからといって上げるものではない。
7. **`homebrew.onActivation.cleanup = "none";`** ([`modules/darwin/default.nix:34`](../../../modules/darwin/default.nix)) **は意図的** (移行期の事故防止)。ユーザーの明示的合意なしに `"zap"` に変えない — 現在のプロファイルに無い cask が一律アンインストールされる。
8. **flake のキー (`darwinConfigurations."<host>"`) は `scutil --get LocalHostName` と一致必須**。ずれていると `darwinConfigurations.<host>.system not found` が出る。

## 標準ワークフロー (どんな変更でも)

1. 上記ルーティング表で**正しい編集先を特定する**。
2. **最小の差分で `.nix` を編集**する。リスト系 (`casks`、`masApps`、`home.packages`、`ignores`) は既存の並び方を尊重 — `casks`/`masApps` はアルファベット順、`packages.nix` はカテゴリ単位。
3. 新規ファイルを作ったなら **`git add --intent-to-add`**。
4. **適用** — `sudo darwin-rebuild switch --flake .` (system + HM 両方)。HM 側だけしか触っておらず cask/mas/`defaults` を変えていない時は `nix run home-manager -- switch --flake .` の方が速い。
5. **目視で確認** — 新ツール / アプリ / 設定が実際にロードされていることを確かめる。zsh の変更なら新しいシェルを開く。`defaults write` 系は `killall Dock` / `killall Finder` / 再ログインが要るキーがある。
6. **switch が失敗したら** エラーを読んで「トラブルシュート」へ。`flake.lock` を消したり `git checkout .` を打ったり、`~/.config/...` を直接編集して「衝突を解消」したりしない — 宣言モデルを破壊する。

## switch 適用前の確認方針

`darwin-rebuild switch` はシステムを変更する操作: `/etc/`、`/Library/` を触り、`brew bundle` を実行し、cask を入れたり消したり、`defaults` を書き込む。デプロイと同等に扱う。

- ユーザーが明示的に「適用してほしい」「インストールしてほしい」「セットアップしてほしい」「試してほしい」と言っている場合 → **無確認で実行して良い**。
- ユーザーが「設定を編集」「変更を計画」しか言っていない場合 → **事前に diff を見せて確認を取る**。
- **ロールバック**: `sudo darwin-rebuild rollback`。世代一覧: `darwin-rebuild --list-generations`。

## トラブルシュート

エラー → 対処は [docs/maintenance.md の「困ったら」](../../../docs/maintenance.md#困ったら) に集約してあるので**先にそれを読む**。多くは上記「厳守ルール」の違反 (#1 intent-to-add 漏れ / #8 ホスト名不一致 / `users.users` 設定漏れ) に着地する。

表に無い症状の場合は [docs/maintenance.md](../../../docs/maintenance.md) を全文読み、失敗したモジュールの `.nix` ソースを実際に開いてから修正案を出す。

## この skill を使わない場面

- ユーザーがこのリポで宣言**していない**ファイル (プロジェクトローカルなコード、`/tmp` の作業ファイルなど) を編集している。dotfiles のモデルが効くのはこのリポの `.nix` モジュールが書き出すファイルだけ。
- ユーザーが何かを一時的に / 1 プロジェクト用にだけ入れたい。その場合はこのリポを編集せず、`nix shell` / プロジェクト単位の `flake.nix` / `mise use` (プロジェクトスコープ) を使う。
- ユーザーがこのリポの**アーキテクチャを質問**している。[`CLAUDE.md`](../../../CLAUDE.md) を直接読む — 非自明な配線はそこに書いてある。
