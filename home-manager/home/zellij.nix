{ config, lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;

    # zellij のデフォルト挙動から唯一外したい差分:
    # `zellij:link` プラグインを新規セッション時に auto-load しない
    # (zellij デフォルトは `load_plugins { "zellij:link" }`)
    settings.load_plugins = { };
  };
}
