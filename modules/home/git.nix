{ config, pkgs, ... }:

let
  # nixpkgs が git 2.54 を取り込むまでの暫定 override。
  # 2.54 で導入された機能を使うため、upstream tarball を直接差し替える。
  # nixpkgs 側が 2.54 以上になったらこのブロックごと削除する。
  gitWithUpstream = pkgs.git.overrideAttrs (old: rec {
    version = "2.54.0";
    src = pkgs.fetchurl {
      url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
      sha256 = "sha256-9okWI2TBDeee+Jqo2/SHMesFfjTtu9IKylEM4BVGgaM=";
    };
    # 2.54 で upstream にマージ済み。重複適用を避けるため除外する。
    patches = builtins.filter
      (p: !(pkgs.lib.hasSuffix
        "osxkeychain-define-build-targets-in-toplevel-Makefile.patch"
        (toString p)))
      old.patches;
  });
in
{
  programs.git = {
    enable = true;
    package = gitWithUpstream;

    settings = {
      user = {
        name = "Fastman";
        email = "gabayt0_0@icloud.com";
      };
      credential.helper = "osxkeychain";
      ghq.root = "/Users/hayato/project";
      init.defaultBranch = "main";
      core.ignorecase = false;
      core.editor = "nvim";
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };
}
