{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;
    # macOS は cask 版を使うため、HM 経由ではバイナリを入れない
    package = null;

    settings = {
      font-size = 14;
      font-family = "Hack Nerd Font Mono";
    };
  };
}
