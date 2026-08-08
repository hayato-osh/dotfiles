{ host, lib, ... }:

{
  programs.nh = {
    enable = true;

    # NH_FLAKE。リポジトリの置き場所はホストごとに違うので flake.nix の hosts が持つ。
    # 未設定のホストでは `nh darwin switch <path>` とパスを明示する。
    flake = lib.mkIf (host.dotfilesPath != null) host.dotfilesPath;

    # GC は modules/darwin/default.nix の nix.gc が持つ。二重に走らせない。
    clean.enable = false;
  };
}
