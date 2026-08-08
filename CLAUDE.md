# CLAUDE.md

macOS 環境を **Nix Flake + nix-darwin + Home Manager** で宣言的に管理する個人 dotfiles。テストもビルド成果物も無い — 設定を「適用する」ことがビルドに相当する。

- 何をどこに足すか / 日常コマンド / セットアップ → [README.md](./README.md)
- 更新チャネル / CI / トラブルシュート → [docs/maintenance.md](./docs/maintenance.md)

このファイルは**非自明な配線と、触ると壊れる制約**だけを持つ。

## マシン固有の値は `flake.nix` の `hosts` にしか書かない

最重要の規約。`modules/` 配下に `/Users/hayato` やホスト名のリテラルを書くと複数ホスト構成が壊れる。モジュールは `specialArgs` / `extraSpecialArgs` 経由で渡る `host` を参照する:

- `host.username` — `modules/darwin/default.nix` の `users.users` / `system.primaryUser`
- `host.homeDirectory` — `home/default.nix`、`macos-defaults.nix` の screencapture、`git.nix` の ghq.root
- `host.system` — `hosts/<profile>/default.nix` の `nixpkgs.hostPlatform`
- `host.profile` — ホスト間で分岐したいとき
- `host.dotfilesPath` — `nh.nix` の `NH_FLAKE` (未設定なら `null`)

公開するホストは `flake.nix` の `publicHosts`、公開したくないホストは追跡外の `hosts.local.nix`。後者の中身をリポジトリ側に移さない — 意図的に隠している。git 参照 (`--flake .`) からは見えないので、`NH_FLAKE` は `path:` 付きで宣言してある (`modules/home/nh.nix`)。裸のパスは git+file: に解決されるので、この `path:` を外さない。

## 4 層構造の境界を越境させない

- **`hosts/<profile>/`** — そのマシンにしか入れないアプリ。`modules/darwin` を import した上で `nixpkgs.hostPlatform` と差分の `casks` / `masApps` を載せる。新ホストは `flake.nix` の 1 エントリ + このファイルだけで足りる。支給機のプロファイルでは `masApps` を空にする (個人 Apple ID でのサインインを前提に置かないため)
- **`modules/darwin/`** — root が要る物 / OS に効く設定。`default.nix` の `users.users.${host.username}` が抜けると HM が `home.homeDirectory ... null` で落ちる
- **`modules/home/`** — ユーザースコープの CLI / シェル / dotfiles。`default.nix` が兄弟モジュールを全部 import するアグリゲータ
- **`home/default.nix`** — 組み立て層。`host` を受けて `modules/home` を import するだけ

HM に cask を入れる、darwin に CLI を入れるのは層を間違えているサイン。

## Homebrew と Nix の境界

**cask に入れて良いのは GUI アプリ (`.app`) だけ。** CLI は nixpkgs (`modules/home/packages.nix`) か mise (`modules/home/mise.nix`)。

brew が構造的に必要なのは (a) App Store 配布物 (`masApps` — ライセンスが Apple ID に紐づき Nix が再配布できない)、(b) `/Library/Input Methods` への pkg インストールが要る入力メソッド、(c) nixpkgs に無い / darwin 非対応のもの。

nixpkgs に darwin 版がある GUI アプリ (chrome, slack, raycast 等) も cask のままにしている。TCC 権限 (アクセシビリティ / 画面収録) がバンドルパスと署名に紐づくため、store path が変わる更新のたびに許可を付け直すことになるのを避けている。

## Sheldon + zsh-defer の組み立て

`modules/home/zsh/default.nix` は `programs.sheldon.enableZshIntegration` を**使わない**。代わりに:

1. `programs.zsh.initContent` で `zsh-defer` を最初に source する (`lib.mkBefore`)。`defer` テンプレートが `zsh-defer source ...` を呼ぶため、sheldon の出力が読まれる前にコマンドが存在している必要がある
2. `sheldon source` を 1 度だけ走らせて `$XDG_CACHE_HOME/sheldon.zsh` に書き出し、`plugins.toml` が新しい時だけ再生成する (シェル起動ごとの実行コストを避けるため)
3. プラグインは `flake = false` の flake input として宣言し、`extraSpecialArgs` 経由で渡す。実行時に取りに行かず Nix store から source する
4. スニペットの置き場は 2 つ — `zsh/sync/` (即時 source) と `zsh/defer/` (zsh-defer 経由)

手動キャッシュのコードを残したまま `enableZshIntegration` を `true` にしない。この 2 つは 1 セット。

## モジュール別の注意点

- **Ghostty** (`modules/home/ghostty.nix`): `package = null;` は意図的。nixpkgs の ghostty は `meta.platforms` に darwin を含まない。バイナリは cask、HM は設定ファイルだけ書く。「直そう」として消さない
- **LazyVim** (`modules/home/nvim/default.nix`): `lazyvim` input (`pfassina/lazyvim-nix`) が **IFD を使う**。darwin 構成は `nix flake check --no-build` では評価できないので `checks` に入れていない。「checks に足しておこう」としない — Linux CI が落ちる
- **mise** がランタイムと「速く追従したい CLI」を所有する。`packages.nix` に node / python を入れない
- **git の identity** (`modules/home/git.nix`): `user.name` / `user.email` を宣言せず、`~/.config/git/local.conf` を include するだけ。未設定のマシンでコミットが落ちるのは意図した挙動 (意図しないアドレスで黙って打つより良い)。`ignores` の `**/.claude/settings.local.json` も外さない
- **Homebrew `cleanup = "none"`** (`modules/darwin/default.nix`): 移行期の誤削除防止。明示的な合意なしに `"zap"` に変えない — プロファイルに無い cask が一律アンインストールされる
- **`home.stateVersion` / `system.stateVersion`** は互換性ピン。最新値に上げる物ではない
