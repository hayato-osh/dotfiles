{ nix-index-database, ... }:

{
  imports = [ nix-index-database.homeModules.nix-index ];

  # comma (`,`) のみ。ラッパが small DB (約 1.2MB) を同梱する。
  programs.nix-index-database.comma.enable = true;

  # nix-locate と command-not-found フックは使わない。
  # 有効にすると full DB (約 60MB) を毎週の flake update ごとに引き直す。
  programs.nix-index.enable = false;
}
