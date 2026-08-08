---
name: dotfiles-maintenance
description: Nix Flake + nix-darwin + Home Manager で管理する macOS dotfiles リポを編集・更新・トラブルシュートするとき。`hosts/`、`modules/`、`home/`、`flake.nix` 配下の編集、Homebrew cask / mas アプリ / nixpkgs CLI / mise ランタイム / `defaults write` / zsh スニペット / LazyVim 設定 / 新ホスト追加 / `nix flake update` / `darwin-rebuild switch` の失敗対応で発火。トリガー語例 - 「cask 追加」「brew で入れたい」「mise の node を上げる」「macOS の dock を」「zsh のエイリアス」「新しい mac のセットアップ」「flake update」「switch が落ちる」。一時的なツール導入や 1 プロジェクト用の依存追加では使わない (代わりに `nix shell` / プロジェクトローカル `flake.nix` / `mise use`)。
---

# dotfiles メンテナンス

このリポジトリは macOS 環境を宣言的に管理する。すべての変更は `.nix` の編集として行い、`nh darwin switch` で適用する。命令的な「とりあえずインストール」ステップは存在しない (唯一の例外が新規 Mac 用の [`scripts/bootstrap.sh`](../../../scripts/bootstrap.sh))。

読む順番:

- **何をどこに足すか** → [README.md の該当節](../../../README.md#何をどこに足すか)。これが唯一のソース。skill 側に複製しない
- **非自明な配線・触ると壊れる制約** → [CLAUDE.md](../../../CLAUDE.md)。編集前に必ず該当節を読む
- **更新・CI・エラー対処** → [docs/maintenance.md](../../../docs/maintenance.md)

## 標準ワークフロー

1. README の「何をどこに足すか」で**編集先を特定**する。載っていないものは CLAUDE.md を読んでから判断する
2. **最小の差分**で `.nix` を編集する。リスト系 (`casks` / `masApps` / `home.packages` / `ignores`) は既存の並びを尊重 — `casks` と `masApps` はアルファベット順、`packages.nix` はカテゴリ単位の `let` バインディング
3. 新規ファイルを作ったら **`git add --intent-to-add <file>`**。`nh` は `path:` 参照なので無くても通るが、`nix build` / `darwin-rebuild --flake .` は git index しか見ずに「ファイルが見つからない」で落ちる
4. `.nix` / `.yaml` を触ったら **`nix fmt`** (CI がフォーマット差分で落ちる)。`*.zsh` は整形対象外
5. **適用** — `nh darwin switch` (`sudo` を付けない。nh が自分で昇格する)。ホスト名がズレているなら `-H <profile>`。適用せず差分だけ見るなら `nh darwin build`
6. **目視で確認** — zsh の変更なら新しいシェル、`defaults write` なら `killall Dock` / `killall Finder` / 再ログインが要るキーがある
7. 失敗したら [docs/maintenance.md の「困ったら」](../../../docs/maintenance.md#困ったら)。`flake.lock` を消す / `git checkout .` する / `~/.config/...` を直接編集して「衝突を解消」する、はしない — 宣言モデルを壊す

## 厳守ルール (過去に踏んだ罠)

1. **新規ファイルは `git add --intent-to-add`**。`nh` 以外 (`nix build` / `darwin-rebuild --flake .`) は git index しか見ない
2. **層の境界をまたがない**。`hosts/` + `modules/darwin/` = root / OS / cask / mas / `defaults` / fonts、`modules/home/` + `home/` = ユーザーの CLI と dotfiles
3. **`modules/` にマシン固有のリテラルを書かない**。`/Users/hayato` と書きたくなったら `${host.homeDirectory}`。**git の user.name / user.email はリポジトリに一切書かない** — 追跡外の `~/.config/git/local.conf` が持つ
4. **cask は GUI アプリ専用**。CLI 専用 cask (`1password-cli` 等) を足さない
5. **ランタイムは mise の領分**。`nodejs` / `python` / `ruby` / `go` を `packages.nix` に入れない
6. **`programs.ghostty.package = null;` は意図的**。消さない
7. **Sheldon 統合は手動配線**。`enableZshIntegration = false;` と `initContent` の `lib.mkBefore` は 1 セット
8. **`stateVersion` は互換性ピン**。上げない
9. **`homebrew.onActivation.cleanup = "none";` を勝手に `"zap"` にしない**
10. **`lazyvim-nix` は IFD を使う**。darwin 構成を `checks` に足さない (Linux CI が落ちる)
11. **ホスト名がズレていても `nh darwin switch -H <profile>` で回避できる**。`scutil --set LocalHostName` を勧める前にそちらを案内する (支給機はホスト名を変えられないことがある)
12. **追跡外ホスト (`hosts.local.nix` / `hosts/<profile>/`) の中身をリポジトリ側に移さない**。`NH_FLAKE` が `path:` 参照なので `nh` からはそのまま見える

## switch 適用前の確認方針

`nh darwin switch` は `/etc/` と `/Library/` を触り、`brew bundle` を走らせ、cask を出し入れし、`defaults` を書き込む。デプロイと同等に扱う。

- ユーザーが「適用して」「入れて」「セットアップして」「試して」と言っている → **無確認で実行して良い**
- 「設定を編集」「変更を計画」しか言っていない → **diff を見せて確認を取る**
- ロールバック: `sudo darwin-rebuild rollback`

## この skill を使わない場面

- このリポが宣言していないファイルの編集 (プロジェクトローカルのコードなど)
- 一時的 / 1 プロジェクト限りの導入 → `nix shell` / プロジェクトの `flake.nix` / `mise use`
- アーキテクチャそのものへの質問 → [CLAUDE.md](../../../CLAUDE.md) を直接読む
