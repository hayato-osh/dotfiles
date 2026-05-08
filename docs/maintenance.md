# メンテナンスガイド

このリポジトリに変更を加えるときの作法をユースケース別にまとめる。新規セットアップは [README.md](../README.md) 参照。

## 大原則

- **新規ファイルを足したら即** `git add --intent-to-add <file>` を実行する。flake 評価器は git index に載っているファイルしか見ない。
- **`switch` で動作確認するまでが 1 サイクル**。`darwin-rebuild check` は構文だけで activation までは見ない。
- 失敗したら `sudo darwin-rebuild rollback` で 1 世代戻す。世代は `darwin-rebuild --list-generations`。

## 何をどこに足すか (判断表)

| 入れたいもの | 行き先 | 例 |
| --- | --- | --- |
| GUI アプリ (App Store 以外) | `darwin/profiles/<host>.nix` の `homebrew.casks` | Brave、Raycast |
| App Store のアプリ | `darwin/profiles/<host>.nix` の `homebrew.masApps` | Xcode、Kindle |
| CLI ツール (バージョン固定不要) | `home-manager/home/packages.nix` | ripgrep、ffmpeg |
| プロジェクトでバージョン切り替えたいランタイム | `home-manager/home/mise.nix` | node、python |
| フォント | `darwin/default.nix` の `fonts.packages` | Nerd Fonts |
| `defaults write` 系の OS 設定 | `darwin/macos-defaults.nix` | Dock の位置、スクショ形式 |
| zsh プラグイン (即時 source) | `home-manager/home/zsh/sync/*.zsh` | options |
| zsh プラグイン (起動高速化のため遅延) | `home-manager/home/zsh/defer/*.zsh` | alias、fzf |
| ツール固有設定 (git/zellij/starship 等) | `home-manager/home/<tool>.nix` | `programs.<tool>.settings` |
| Neovim プラグインの override | `home-manager/home/nvim/default.nix` の `plugins.overrides` (Lua 文字列) | mini.pairs カスタム |

## レシピ

### Homebrew cask を 1 つ足す

`darwin/profiles/personal.nix` の `casks` に行を追加 → switch。

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

### App Store アプリを足す (mas)

`darwin/profiles/personal.nix` の `masApps` に追加。ID は `mas search <name>` で取る。

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

App Store にサインインしていないと switch 時に mas が落ちる。

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

`home-manager/home/mise.nix` の `globalConfig.tools` を編集 → switch → `mise install` を打ち直す必要は無い (HM が `~/.config/mise/config.toml` を書き出すので mise が自動で取りに行く)。

```nix
tools = {
  node = "22.18.0";              # バージョン上げ
  ruby = "3.3";                  # 新規追加
  "npm:@google/gemini-cli" = "latest";
};
```

プロジェクト固有の `.tool-versions` / `.mise.toml` には触らない。グローバルだけ宣言する。

### macOS の `defaults write` を足す

`darwin/macos-defaults.nix` の該当ドメインに追記。プロパティ名は [nix-darwin の system.defaults リファレンス](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-system.defaults) に揃える (生の domain 名と微妙に違う物がある)。

ドメインに無いキーを足したい場合は:

```nix
system.defaults.CustomUserPreferences = {
  "com.apple.dock" = { "some-key" = 1; };
};
```

switch 後、変更によっては `killall Dock` / `killall Finder` / 再ログインが必要。

### zsh のエイリアスや関数を足す

- 即時に効かせたい (PATH や options 系): `home-manager/home/zsh/sync/<name>.zsh`
- 起動を遅らせて良い (alias、補完、fzf 拡張): `home-manager/home/zsh/defer/<name>.zsh`

ファイルを置いただけで sheldon が拾う。switch するまで反映されないので注意。

### Neovim (LazyVim) のプラグインを上書き / 追加

`home-manager/home/nvim/default.nix` の `plugins.overrides` に Lua 文字列で書く。LazyVim 本体の更新は `nix flake update` で `lazyvim` input を引く。

colorscheme を変える時は `plugins.colorscheme` を差し替える。

### git の global ignore を足す

`home-manager/home/git.nix` の `ignores` に追記。グローバル ignore に入れて良いのは「どのリポジトリでも絶対コミットしない」物だけ (例: `.claude/settings.local.json`)。

```nix
ignores = [
  "**/.claude/settings.local.json"
  ".DS_Store"
];
```

### 新しいモジュールを 1 つ切り出す

例: `programs.ssh` を分離する。

1. `home-manager/home/ssh.nix` を作って `programs.ssh = { ... };` を書く。
2. `home-manager/home/common.nix` の `imports` に `./ssh.nix` を足す。
3. `git add --intent-to-add home-manager/home/ssh.nix`。
4. `sudo darwin-rebuild switch --flake .`。

`darwin/` 側に新規モジュールを切り出すときも同様に `darwin/default.nix` の `imports` に追加するか、`flake.nix` の `modules = [ ... ]` に直接足す。

## 更新作業

### nixpkgs / lazyvim 等を更新

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

`onActivation.upgrade = false;` (`darwin/default.nix`) なので switch では cask は上がらない。手動で:

```sh
brew upgrade --cask
brew upgrade
```

cleanup も `"none"` 固定なので、profile から外した cask は手で `brew uninstall --cask <name>` する。一律削除したくなったら `darwin/default.nix` の `cleanup` を `"zap"` に変える (移行期は意図的に避けている)。

## 新ホスト追加 (work マシン等)

1. `darwin/profiles/work.nix` を `personal.nix` を雛形にコピーして cask/mas を編集。
2. `flake.nix` に 1 エントリ追加:

   ```nix
   darwinConfigurations."<work-host>" = nix-darwin.lib.darwinSystem {
     modules = [
       ./darwin/default.nix
       ./darwin/profiles/work.nix
       home-manager.darwinModules.home-manager
       {
         home-manager.useGlobalPkgs = true;
         home-manager.useUserPackages = true;
         home-manager.extraSpecialArgs = hmExtraSpecialArgs;
         home-manager.users.hayato = { imports = hmCommonModules; };
       }
     ];
   };
   ```

3. work マシン側で `scutil --get LocalHostName` を確認し `<work-host>` と一致させる (`sudo scutil --set LocalHostName <name>`)。
4. work マシンで [README.md](../README.md) の新規セットアップ手順を実行。

ユーザーや HM 側の設定がホスト間で違う場合は `home-manager/home/work.nix` を切って `hmCommonModules` を分岐させる。現状は 1 ユーザー前提なのでベタに置いている。

## 困ったら

| 症状 | 対処 |
| --- | --- |
| `system activation must now be run as root` | `sudo` を付ける |
| `darwinConfigurations.<host>.system not found` | `flake.nix` のキー名と `scutil --get LocalHostName` を一致させる |
| `home.homeDirectory ... null` | `darwin/default.nix` の `users.users.<user>` から `name` / `home` が抜けていないか確認 |
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

- **flake のキー (`HayatonoMacBook-Pro`) と `scutil --get LocalHostName` は一致必須**。違うと `darwinConfigurations.<host>.system` が無いと言われる。
- **`darwin/` と `home-manager/` は越境させない**。root が要る物 / OS 設定 / cask / mas は `darwin/`、ユーザー dotfiles は `home-manager/`。
- **Ghostty バイナリは cask、設定は HM**。`programs.ghostty.package = null;` は意図的 (`ghostty.nix:7`)。
- **mise がランタイムの一次ソース**。`packages.nix` に node や python を入れない。
- **Sheldon は手動キャッシュ経由で source している**。`enableZshIntegration = false;` と `initContent` の `lib.mkBefore` は連動しているので片方だけ触らない。
- **`home.stateVersion` / `system.stateVersion` は互換性ピン**。最新値に上げる物ではない。
- **Homebrew `cleanup = "none"`** は移行期の保険。profile に無い cask は自動削除されない。
