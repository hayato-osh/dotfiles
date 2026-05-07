{ config, lib, pkgs, zsh-autosuggestions, zsh-completions, zsh-syntax-highlighting, ... }:

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
      cache_dir=''${XDG_CACHE_HOME:-$HOME/.cache}
      sheldon_cache="$cache_dir/sheldon.zsh"
      sheldon_toml="$HOME/.config/sheldon/plugins.toml"
      if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
        mkdir -p "$cache_dir"
        sheldon source > "$sheldon_cache"
      fi
      source "$sheldon_cache"
      unset cache_dir sheldon_cache sheldon_toml

      # bun completions
      [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
    '';
  };

  programs.sheldon = {
    enable = true;
    # zsh-defer を先に source した上で手動キャッシュ経由で読むため、自動統合は無効化
    enableZshIntegration = false;

    settings = {
      shell = "zsh";

      templates = {
        defer = ''{{ hooks?.pre | nl }}{% for file in files %}zsh-defer source "{{ file }}"
{% endfor %}{{ hooks?.post | nl }}'';
      };

      plugins = {
        zsh-autosuggestions = {
          local = "${zsh-autosuggestions}";
          use = [ "{{ name }}.zsh" ];
        };
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
