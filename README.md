# dotfiles

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する。すべての変更は `.nix` の編集で、適用は `nh darwin switch` の 1 コマンド。

- マシン固有の値 (ホスト名 / ユーザー名) は `flake.nix` の `publicHosts` に集約する。`modules/` にリテラルを書かない
- git の identity と署名鍵だけはリポジトリに載せない (public なので)。追跡外の `~/.config/git/local.conf`
- 支給機など公開したくないホストは追跡外の `hosts.local.nix` + `hosts/<profile>/` に置く。`nh` は `path:` でリポを読むのでそのまま切り替わる (git 参照の `--flake .` からは見えない)

## セットアップ (新規 Mac)

```sh
xcode-select --install                                    # git を使えるようにする
mkdir -p ~/project/github.com/hayato-osh && cd $_
git clone https://github.com/hayato-osh/dotfiles.git && cd dotfiles
./scripts/bootstrap.sh
```

`bootstrap.sh` が Xcode CLT / Homebrew / Nix / git identity / 署名鍵 / 初回 switch までやる。冪等なので途中で落ちても再実行でよい。`--dry-run` で実行内容だけ確認できる。

- 実ホスト名が `publicHosts.<profile>.hostName` と一致しない場合は `--profile <name>` で明示する
- 手作業でしか済まないのは 2 つ — **App Store のサインイン** (してから再実行すると `masApps` が入る) と、**GUI アプリの権限許可** (初回起動時)

## 構成

- `flake.nix` — ホスト定義 (`publicHosts`) と `darwinConfigurations` / `formatter` / `checks`
- `hosts/<profile>/` — そのマシンにしか入れない cask / mas
- `modules/darwin/` — システムスコープ。共通 cask、`defaults write`、フォント、nix 設定
- `modules/home/` — ユーザースコープ。CLI、シェル、各ツールの dotfiles
- `home/` — `host` から username / homeDirectory を受けて `modules/home` を import するだけ
- `scripts/bootstrap.sh` — 新規 Mac のセットアップ

## 日常運用

- `nh darwin switch` — system + HM を反映。**`sudo` を付けない** (nh が自分で昇格する)
- `nh darwin switch -H <profile>` — ホスト名と `hostName` がズレている時、別プロファイルを当てたい時
- `nh darwin build` — 適用せずビルドして、前世代との差分だけ見る
- `nix fmt` — 整形。コミット前に必須
- `sudo darwin-rebuild rollback` — 1 つ前の世代に戻す (`darwin-rebuild --list-generations` で一覧)

`NH_FLAKE` がこのリポを `path:` で指しているので、どのディレクトリからでも打てて、git 未追跡のファイル (`hosts.local.nix` など) も読む。`nh` を挟まず `darwin-rebuild --flake .` を直接打つ場合だけは git 参照になるので、新規ファイルに先に `git add --intent-to-add <file>` が要る。

Home Manager 単体の切り替えコマンドは無い。この構成の HM は nix-darwin モジュール経由なので `homeConfigurations` を出力していない。

## 何をどこに足すか

- **GUI アプリ (全ホスト共通)** → `modules/darwin/apps.nix` の `homebrew.casks`
- **GUI アプリ (特定のマシンだけ)** → `hosts/<profile>/default.nix` の `homebrew.casks`
- **App Store アプリ** → `hosts/<profile>/default.nix` の `homebrew.masApps` (ID は `mas search <name>`)
- **CLI ツール** → `modules/home/packages.nix`
- **ランタイム / 速く追従したい CLI** → `modules/home/mise.nix` の `globalConfig.tools`
- **フォント** → `modules/darwin/default.nix` の `fonts.packages`
- **`defaults write` 系の OS 設定** → `modules/darwin/macos-defaults.nix`
- **zsh スニペット** → `modules/home/zsh/sync/*.zsh` (即時) か `defer/*.zsh` (遅延)
- **ツール固有の設定** → `modules/home/<tool>.nix`
- **マシン固有の値 / 新ホスト** → `flake.nix` の `publicHosts` + `hosts/<profile>/default.nix`
- **git の identity / 署名鍵** → リポジトリ外の `~/.config/git/local.conf`
- **ssh の per-machine 設定** → リポジトリ外の `~/.ssh/config.local` (無くてよい)

**Homebrew は GUI アプリ (`.app`) 専用。** CLI は nixpkgs か mise に置く (`1password-cli` のような CLI 専用 cask を足さない)。

---

更新・トラブルシュート・CI は [docs/maintenance.md](./docs/maintenance.md)、非自明なアーキテクチャ上の制約は [CLAUDE.md](./CLAUDE.md)。
