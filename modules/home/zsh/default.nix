{
  config,
  lib,
  pkgs,
  zsh-completions,
  zsh-syntax-highlighting,
  ...
}:

{
  programs.zsh = {
    enable = true;

    # zsh-defer を sheldon より先に読み込む。
    # defer テンプレートは zsh-defer コマンドを呼ぶため、sheldon source の前に
    # 利用可能になっている必要がある。
    # https://kyre.moe/ja/blog/sheldon-nix
    initContent = lib.mkBefore ''
      source "${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh"

      # sheldon source のキャッシュ
      # https://zenn.dev/fuzmare/articles/zsh-plugin-manager-cache
      # plugins.toml は Nix store symlink (mtime=1970) で mtime 比較が使えないため、
      # symlink の解決先 store path をキーにする — 内容が変われば store path が変わる。
      # 同じ理由で sheldon 内部の plugins.lock も stale 化するので、キー変動時は強制再生成。
      cache_dir=''${XDG_CACHE_HOME:-$HOME/.cache}
      sheldon_cache="$cache_dir/sheldon.zsh"
      sheldon_keyfile="$cache_dir/sheldon.zsh.key"
      sheldon_toml="$HOME/.config/sheldon/plugins.toml"
      sheldon_key="$(readlink "$sheldon_toml" 2>/dev/null || echo missing)"
      if [[ ! -r "$sheldon_cache" || ! -r "$sheldon_keyfile" || "$(<"$sheldon_keyfile")" != "$sheldon_key" ]]; then
        mkdir -p "$cache_dir"
        sheldon lock >/dev/null 2>&1
        sheldon source > "$sheldon_cache"
        print -r -- "$sheldon_key" > "$sheldon_keyfile"
      fi
      source "$sheldon_cache"
      unset cache_dir sheldon_cache sheldon_keyfile sheldon_toml sheldon_key
    '';
  };

  programs.sheldon = {
    enable = true;
    # zsh-defer を先に source した上で手動キャッシュ経由で読むため、自動統合は無効化
    enableZshIntegration = false;

    settings = {
      shell = "zsh";

      templates = {
        defer = ''
          {{ hooks?.pre | nl }}{% for file in files %}zsh-defer source "{{ file }}"
          {% endfor %}{{ hooks?.post | nl }}'';
      };

      plugins = {
        zsh-completions = {
          local = "${zsh-completions}";
          apply = [ "defer" ];
        };
        zsh-syntax-highlighting = {
          local = "${zsh-syntax-highlighting}";
          apply = [ "defer" ];
        };

        dotfiles-sync = {
          local = "${./sync}";
          use = [ "*.zsh" ];
        };
        dotfiles-defer = {
          local = "${./defer}";
          use = [ "*.zsh" ];
          apply = [ "defer" ];
        };
      };
    };
  };
}
