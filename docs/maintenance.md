# メンテナンスガイド

このリポジトリに変更を加えるときの作法をユースケース別にまとめる。新規セットアップは [README.md](../README.md) 参照。

## 大原則

- **新規ファイルを足したら即** `git add --intent-to-add <file>` を実行する。flake 評価器は git index に載っているファイルしか見ない。
- **`switch` で動作確認するまでが 1 サイクル**。`darwin-rebuild check` は構文だけで activation までは見ない。
- **コミット前に `nix fmt`**。CI (`.github/workflows/lint.yaml`) がフォーマット差分で落ちる。
- **マシン固有の値は `flake.nix` の `publicHosts` (公開しないなら `hosts.local.nix`) にしか書かない**。`modules/` 配下にユーザー名やホスト名のリテラルを埋めない (`host.username` / `host.homeDirectory` を参照する)。
- **メールアドレスをリポジトリに書かない**。git の identity は追跡外の `~/.config/git/local.conf`。
- 失敗したら `sudo darwin-rebuild rollback` で 1 世代戻す。世代は `darwin-rebuild --list-generations`。

## 何をどこに足すか (判断表)

| 入れたいもの | 行き先 | 例 |
| --- | --- | --- |
| GUI アプリ — 全マシン共通 | `modules/darwin/apps.nix` の `homebrew.casks` | Ghostty、1Password |
| GUI アプリ — 片方のマシンだけ | `hosts/<profile>/default.nix` の `homebrew.casks` | Discord (個人機のみ) |
| App Store のアプリ | `hosts/<profile>/default.nix` の `homebrew.masApps` | Xcode、Kindle |
| マシン固有の値 (ホスト名 / ユーザー名) | `flake.nix` の `publicHosts` | `publicHosts.personal.username` |
| 公開したくないホストの定義 | **追跡外** — `hosts.local.nix` + `hosts/<profile>/` | — |
| git の identity (user.name / user.email) | **リポジトリ外** — `~/.config/git/local.conf` | — |
| CLI ツール (バージョン固定不要) | `modules/home/packages.nix` | ripgrep、ffmpeg |
| プロジェクトでバージョン切り替えたいランタイム | `modules/home/mise.nix` | node、python |
| フォント | `modules/darwin/default.nix` の `fonts.packages` | Nerd Fonts |
| `defaults write` 系の OS 設定 | `modules/darwin/macos-defaults.nix` | Dock の位置、スクショ形式 |
| zsh プラグイン (即時 source) | `modules/home/zsh/sync/*.zsh` | options |
| zsh プラグイン (起動高速化のため遅延) | `modules/home/zsh/defer/*.zsh` | alias、fzf |
| ツール固有設定 (git/starship 等) | `modules/home/<tool>.nix` | `programs.<tool>.settings` |
| Neovim プラグインの override | `modules/home/nvim/default.nix` の `plugins.overrides` (Lua 文字列) | mini.pairs カスタム |

## レシピ

### Homebrew cask を 1 つ足す

まず「両方のマシンに要るか」を決める。

- 両方 → `modules/darwin/apps.nix` の `casks`
- 片方だけ → `hosts/<profile>/default.nix` の `casks`

```nix
homebrew.casks = [
  # ...
  "rectangle"
];
```

```sh
sudo darwin-rebuild switch --flake .
```

cask 名は [formulae.brew.sh/cask](https://formulae.brew.sh/cask/) で確認。

**cask に入れて良いのは GUI アプリ (`.app`) だけ。** CLI は nixpkgs (`modules/home/packages.nix`) か mise (`modules/home/mise.nix`) の担当。`1password-cli` や `claude-code` のような CLI 専用 cask を足さない。

### App Store アプリを足す (mas)

`hosts/<profile>/default.nix` の `masApps` に追加。ID は `mas search <name>` で取る。

```sh
mas search Xcode
# 497799835 Xcode (16.4)
```

```nix
masApps = {
  # ...
  "Xcode" = 497799835;
};
```

App Store にサインインしていないと switch 時に mas が落ちる。支給機のプロファイルでは `masApps` を空にしておくとよい — 個人 Apple ID でのサインインを前提に置かないため。

### CLI ツール (nixpkgs) を足す

カテゴリの近い `let` バインディングに追記する。`packages.nix`:

```nix
modernCli = with pkgs; [
  # ...
  delta  # diff viewer
];
```

新しいカテゴリを切る場合は `let` に変数を増やしてから `home.packages = ... ++ newCategory;` に連結。

[search.nixos.org/packages](https://search.nixos.org/packages) で名前を確認。

### mise でランタイムを増やす / バージョンを上げる

`modules/home/mise.nix` の `globalConfig.tools` を編集 → switch → `mise install` を打ち直す必要は無い (HM が `~/.config/mise/config.toml` を書き出すので mise が自動で取りに行く)。

```nix
tools = {
  node = "22.18.0";              # バージョン上げ
  ruby = "3.3";                  # 新規追加
  "npm:@google/gemini-cli" = "latest";
};
```

プロジェクト固有の `.tool-versions` / `.mise.toml` には触らない。グローバルだけ宣言する。

### macOS の `defaults write` を足す

`modules/darwin/macos-defaults.nix` の該当ドメインに追記。プロパティ名は [nix-darwin の system.defaults リファレンス](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults) に揃える (生の domain 名と微妙に違う物がある)。

ドメインに無いキーを足したい場合は:

```nix
system.defaults.CustomUserPreferences = {
  "com.apple.dock" = { "some-key" = 1; };
};
```

switch 後、変更によっては `killall Dock` / `killall Finder` / 再ログインが必要。

### zsh のエイリアスや関数を足す

- 即時に効かせたい (PATH や options 系): `modules/home/zsh/sync/<name>.zsh`
- 起動を遅らせて良い (alias、補完、fzf 拡張): `modules/home/zsh/defer/<name>.zsh`

ファイルを置いただけで sheldon が拾う。switch するまで反映されないので注意。

### Neovim (LazyVim) のプラグインを上書き / 追加

`modules/home/nvim/default.nix` の `plugins.overrides` に Lua 文字列で書く。LazyVim 本体の更新は `nix flake update` で `lazyvim` input を引く。

colorscheme を変える時は `plugins.colorscheme` を差し替える。

### git の identity (name / email)

**このリポジトリには書かない。** public リポジトリにメールアドレスを載せないため、`modules/home/git.nix` は `user.name` / `user.email` を宣言せず、追跡外のファイルを include するだけにしてある。

マシンごとに 1 回だけ作る:

```sh
cat > ~/.config/git/local.conf <<'EOF'
[user]
	name = <名前>
	email = <そのマシンで使うメールアドレス>
EOF
```

- HM が書き出す `~/.config/git/config` の末尾に `[include] path = ~/.config/git/local.conf` が入っている (`includes` は `mkAfter` なので、リポジトリ側の設定より後に読まれる = 優先される)。
- ファイルが無ければ git は黙って無視する。その状態でコミットしようとすると `Please tell me who you are` で落ちる。**これは意図した挙動** — 意図しないアドレスで黙ってコミットされるより、明示的に落ちたほうが良い。
- `~/.config/git/` は HM の管理下だが、`local.conf` は宣言していないので switch で消えない。

### git の global ignore を足す

`modules/home/git.nix` の `ignores` に追記。グローバル ignore に入れて良いのは「どのリポジトリでも絶対コミットしない」物だけ (例: `.claude/settings.local.json`)。

```nix
ignores = [
  "**/.claude/settings.local.json"
  ".DS_Store"
];
```

### 新しいモジュールを 1 つ切り出す

例: `programs.ssh` を分離する。

1. `modules/home/ssh.nix` を作って `programs.ssh = { ... };` を書く。
2. `modules/home/default.nix` の `imports` に `./ssh.nix` を足す。
3. `git add --intent-to-add modules/home/ssh.nix`。
4. `sudo darwin-rebuild switch --flake .`。

`modules/darwin/` 側に新規モジュールを切り出すときも同様に `modules/darwin/default.nix` の `imports` に追加する。

## 更新作業

### nixpkgs / lazyvim 等を更新

毎週月曜 03:00 UTC に `.github/workflows/update-flake.yaml` が `nix flake update` して PR を出す。通常はその PR をマージして各マシンで switch するだけで良い。

手で回す場合:

```sh
nix flake update
sudo darwin-rebuild switch --flake .
```

問題があれば `git checkout flake.lock` で戻して再 switch。

### 個別 input だけ更新

```sh
nix flake update nixpkgs
nix flake update lazyvim
```

### Homebrew パッケージ自体の更新

`onActivation.upgrade = false;` (`modules/darwin/default.nix`) なので switch では cask は上がらない。手動で:

```sh
brew upgrade --cask
brew upgrade
```

cleanup も `"none"` 固定なので、profile から外した cask は手で `brew uninstall --cask <name>` する。一律削除したくなったら `modules/darwin/default.nix` の `cleanup` を `"zap"` に変える (移行期は意図的に避けている)。

## フォーマットと CI

```sh
nix fmt                                  # 全ファイル整形 (nixfmt + yamlfmt)
nix flake check --all-systems --no-build # flake 出力のスキーマ検査
nix build .#darwinConfigurations.personal.system --no-link  # 構成を実際にビルド
```

対象と除外は `treefmt.nix`。`*.zsh` は除外している (shfmt が zsh 固有構文を壊すため)。

CI は 2 本:

| workflow | runner | 内容 |
| --- | --- | --- |
| `lint.yaml` / `lint` | ubuntu | `nix flake check` + フォーマット検査 |
| `lint.yaml` / `build-darwin` | macOS | `personal` の構成を実ビルド |
| `update-flake.yaml` | ubuntu | 週次 `nix flake update` → PR |

`build-darwin` を macOS runner に置いているのは、`lazyvim-nix` が `~/.config/nvim` を走査する derivation を `builtins.readFile` する (IFD) ため。Linux からは aarch64-darwin の IFD を実行できず、`--no-build` でも評価が通らない。だから `checks` には darwin 構成を含めていない。

`update-flake.yaml` が PR を作れるようにするには、GitHub リポジトリの Settings → Actions → General で **Allow GitHub Actions to create and approve pull requests** を有効にする必要がある。

## 新ホスト追加

1. `flake.nix` の `publicHosts` に 1 エントリ追加する。マシン固有の値はここだけ。
   ホスト名やアカウント名を公開したくないマシンは、`publicHosts` ではなく**追跡外の `hosts.local.nix`** に同じ形で書く (`.gitignore` 済み)。その場合 `hosts/<profile>/` も追跡外にし、switch は `--flake path:.#<profile>` を使う。

   ```nix
   hosts = {
     # ...
     newmachine = {
       hostName = "<scutil --get LocalHostName の出力>";
       system = "aarch64-darwin";       # Intel なら "x86_64-darwin"
       username = "<whoami の出力>";
     };
   };
   ```

2. `hosts/<profile>/default.nix` を作る。共通 cask は `modules/darwin/apps.nix` にあるので、ここには差分だけ書く。
3. `git add --intent-to-add hosts/<profile>/default.nix`。
4. そのマシンで [README.md](../README.md) のセットアップ手順を実行し、`sudo darwin-rebuild switch --flake .#<profile>`。

`hostName` が実機と一致していれば `--flake .` だけでも通る (`flake.nix` が論理名と実ホスト名の両方に構成を生やしているため)。一致していなくても `--flake .#<profile>` で明示すれば動くので、ホスト名を変えられない支給機でも困らない。

ホストごとに HM 側の設定を変えたくなったら、`host.profile` (`"personal"` / `"work"`) で分岐する。例:

```nix
home.packages = lib.optionals (host.profile == "work") [ pkgs.awscli2 ];
```

## 困ったら

| 症状 | 対処 |
| --- | --- |
| `system activation must now be run as root` | `sudo` を付ける |
| `darwinConfigurations.<host>.system not found` | `--flake .#personal` / `--flake .#work` とプロファイル名で明示する。恒久的に直すなら `flake.nix` の `hosts.<profile>.hostName` を `scutil --get LocalHostName` の出力に合わせる |
| `home.homeDirectory ... null` | `modules/darwin/default.nix` の `users.users.${host.username}` から `name` / `home` が抜けていないか確認 |
| CI の formatting が落ちる | 手元で `nix fmt` してコミットし直す |
| flake が新規ファイルを認識しない | `git add --intent-to-add <file>` |
| `hm-session-vars.sh: no such file` | `.zprofile` で手動 source している行を消す。HM が `.zshenv` から store 上のパスを直接 source している |
| switch がファイル衝突で落ちる (`~/.config/...` already exists) | `--backup-extension bk` を付けて再 switch、または該当ファイルを退避 |
| `mas: not signed in` | App Store アプリで Apple ID にサインインしてから再 switch |
| Homebrew が見つからない | `/opt/homebrew/bin/brew` の存在を確認。Apple Silicon は `/opt/homebrew`、Intel は `/usr/local` |

ロールバック:

```sh
sudo darwin-rebuild rollback
darwin-rebuild --list-generations
```

## アーキテクチャの非自明な制約

AI 向けに [CLAUDE.md](../CLAUDE.md) に詳細があるが、人が読むべき要点:

- **マシン固有の値は `flake.nix` の `hosts` attrset が唯一のソース**。`modules/` 配下に `/Users/hayato` のようなリテラルを書かない。`host.username` / `host.homeDirectory` / `host.profile` を参照する。
- **git の identity はリポジトリに載せない**。`~/.config/git/local.conf` を include している。public リポジトリにメールアドレスを出さないため。
- **公開したくないホストはコミットしない**。`hosts.local.nix` と `hosts/<profile>/` を追跡外に置き、そのマシンだけ `--flake path:.#<profile>` で switch する。
- **`hosts/` `modules/darwin/` `modules/home/` `home/` の境界を越境させない**。root が要る物 / OS 設定 / cask / mas は `hosts/` + `modules/darwin/`、ユーザー dotfiles は `modules/home/` + `home/`。
- **cask は GUI アプリ専用**。CLI は nixpkgs か mise。この境界が崩れると「brew と nix のどちらに入っているか」が分からなくなる。
- **`lazyvim-nix` は IFD を使う**。そのため darwin 構成の検証には macOS が要る (Linux CI からは評価できない)。
- **Ghostty バイナリは cask、設定は HM**。`programs.ghostty.package = null;` は意図的 (`modules/home/ghostty.nix`)。
- **mise がランタイムの一次ソース**。`packages.nix` に node や python を入れない。
- **Sheldon は手動キャッシュ経由で source している**。`enableZshIntegration = false;` と `initContent` の `lib.mkBefore` は連動しているので片方だけ触らない。
- **`home.stateVersion` / `system.stateVersion` は互換性ピン**。最新値に上げる物ではない。
- **Homebrew `cleanup = "none"`** は移行期の保険。profile に無い cask は自動削除されない。
