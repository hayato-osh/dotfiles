# メンテナンス

日々の更新、CI、詰まったときの対処。何をどこに足すかの判断と新規セットアップは [README.md](../README.md)。

## 大原則

- 適用は `nh darwin switch`。`sudo` は付けない (nh 自身が昇格する。root で呼ぶと弾かれる)
- コミット前に `nix fmt`。CI がフォーマット差分で落ちる
- マシン固有の値は `flake.nix` の `publicHosts` (公開しないなら `hosts.local.nix`) だけに書く。`modules/` では `host.username` / `host.homeDirectory` を参照する
- メールアドレスをリポジトリに書かない。git の identity と署名鍵は追跡外の `~/.config/git/local.conf`
- `nix build` や `darwin-rebuild --flake .` を直接打つときは、新規ファイルに `git add --intent-to-add <file>` が要る。これらは git 参照で、index に載っていないファイルを見ない (`nh` は `path:` 参照なので不要)
- `switch` が通るまでが 1 サイクル。壊したら `sudo darwin-rebuild rollback` (世代一覧は `darwin-rebuild --list-generations`)

## 更新チャネル

4 系統あり、**それぞれ独立している**。1 つ動かしても他は動かない。switch で上がるのは nixpkgs 由来のものだけで、cask / mise / App Store アプリは switch では一切動かない。

### nixpkgs (flake.lock)

毎週月曜 03:00 UTC に `update-flake.yaml` が `nix flake update` して PR を出す。**マージしただけ・pull しただけでは何も変わらない** — 実体が入れ替わるのは switch のとき。

```sh
git pull && nh darwin switch
nix flake update nixpkgs        # 個別 input だけ手で回す場合
```

nixpkgs が進むと**そこに含まれる全パッケージが一斉に上がる**。個別バージョンは指定していない。問題があれば `git checkout flake.lock` して再 switch、または rollback。

### Homebrew

`autoUpdate = false` / `upgrade = false` なので switch は cask も brew 本体も更新しない。一方 cask の定義は API から常に最新が降ってくるため、放置すると本体だけ古くなり `undefined method '...' for Cask` で `brew bundle` が落ちる。数週間に一度 `brew update` する。

`cleanup = "none"` 固定なので、profile から外した cask は手で `brew uninstall --cask <name>`。

### mise

`latest` 指定は `mise upgrade` で引き直す。バージョン固定のものは `modules/home/mise.nix` を書き換えて switch (`mise install` を別途打つ必要は無い — HM が `~/.config/mise/config.toml` を書けば mise が取りに行く)。`mise list` で `(missing)` と出るものは宣言だけで未取得。cask から mise に移したツールを消す前に必ず確認する。

### App Store

App Store アプリ側で更新する。`masApps` は「入っていること」しか宣言していない。

## CI

- `lint.yaml` / `lint` (ubuntu) — `nix flake check --all-systems --no-build` とフォーマット検査
- `lint.yaml` / `build-darwin` (macOS) — `personal` の構成を実ビルド
- `update-flake.yaml` (ubuntu) — 週次 `nix flake update` → PR

`build-darwin` が macOS runner なのは、`lazyvim-nix` が IFD を使う (`~/.config/nvim` を走査する derivation を `builtins.readFile` する) ため。Linux からは aarch64-darwin の IFD を実行できず `--no-build` でも評価が通らない。だから `checks` に darwin 構成を入れていない。

`update-flake.yaml` が PR を作るには、Settings → Actions → General の **Allow GitHub Actions to create and approve pull requests** が要る。

### CI が担保しない範囲

通るのは「Nix の式が壊れていない / パッケージがビルドできる」までで、以下は実機の switch が最初の検証になる:

- **cask / mas** — `brew bundle` は activation 時に走る。cask 名が実在するかも検証されない
- **mise のツール** — HM は config.toml を書くだけ
- **activation そのもの** — `defaults write`、launchd、`$HOME` のファイル衝突
- **公開していないホスト** — `hosts.local.nix` は CI の checkout に入らない

switch が落ちること自体は想定内。世代が残っているので rollback で戻す。

## ホストを足す

1. `flake.nix` の `publicHosts` に 1 エントリ (`hostName` / `system` / `username`、任意で `dotfilesPath`)。公開したくないマシンは同じ形を**追跡外の `hosts.local.nix`** に書く
2. `hosts/<profile>/default.nix` を作る。`nixpkgs.hostPlatform` と、共通 cask (`modules/darwin/apps.nix`) との差分だけ
3. `git add --intent-to-add hosts/<profile>/default.nix`
4. そのマシンで `./scripts/bootstrap.sh`

`hostName` が実機と一致していれば `nh darwin switch` だけで通る (論理名と実ホスト名の両方に構成を生やしている)。一致しなくても `-H <profile>` で明示すれば動くので、ホスト名を変えられない支給機でも困らない。

ホストごとに設定を分けたくなったら `host.profile` で分岐する:

```nix
home.packages = lib.optionals (host.profile == "work") [ pkgs.awscli2 ];
```

## 困ったら

- **`system activation must now be run as root`** — `darwin-rebuild` を直接打っている。`sudo` を付ける (`nh` なら不要)
- **nh が root で呼ばれたと言って止まる** — `sudo nh` にしている。`nh` 単体で打つ
- **`darwinConfigurations.<host>.system not found`** — `nh darwin switch -H <profile>` で明示する。恒久的に直すなら `hostName` を `scutil --get LocalHostName` に合わせる
- **`home.homeDirectory ... null`** — `modules/darwin/default.nix` の `users.users.${host.username}` から `name` / `home` が抜けている
- **flake が新規ファイルを認識しない** — `nix build` / `darwin-rebuild` を直接打っている。`git add --intent-to-add <file>`
- **CI の formatting が落ちる** — 手元で `nix fmt` してコミットし直す
- **switch がファイル衝突で落ちる** — HM が既存ファイルを `.bk` に退避する (`backupFileExtension`)。`.bk` が既にあると落ちるので、その時は手で消す
- **`Please tell me who you are`** — `~/.config/git/local.conf` が無い。`./scripts/bootstrap.sh` で作れる
- **`gpg failed to sign the data` / `user.signingkey needs to be set`** — 同じく `local.conf` に `user.signingkey` が無い。`./scripts/bootstrap.sh` を再実行すると署名鍵のステップだけ走る
- **署名した本人のコミットが `git log --show-signature` で `No principal matched`** — `~/.config/git/allowed_signers` に `<email> <公開鍵>` の行が無い。GitHub 上の Verified 表示とは独立 (あちらは GitHub に登録した Signing key を見る)
- **`mas: not signed in`** — App Store にサインインしてから再 switch
- **`Cask '<name>' definition is invalid`** — `brew update` してから再 switch
- **`hm-session-vars.sh: no such file`** — `.zprofile` で手動 source している行を消す。HM が `.zshenv` から store のパスを直接 source している
