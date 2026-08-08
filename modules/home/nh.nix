{ host, lib, ... }:

{
  programs.nh = {
    enable = true;

    # NH_FLAKE。リポジトリの置き場所はホストごとに違うので flake.nix の hosts が持つ。
    # path: を付けるのは、裸のパスだと git+file: に解決されて追跡外の
    # hosts.local.nix が見えなくなるため。未設定のホストでは `nh darwin switch path:.`。
    flake = lib.mkIf (host.dotfilesPath != null) "path:${host.dotfilesPath}";

    # GC は modules/darwin/default.nix の nix.gc が持つ。二重に走らせない。
    clean.enable = false;
  };
}
