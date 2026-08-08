{
  host,
  lib,
  pkgs,
  ...
}:

let
  # nixpkgs が git 2.54 を取り込むまでの暫定 override。
  # 2.54 で導入された機能を使うため、upstream tarball を直接差し替える。
  #
  # nixpkgs 側が追いついたら switch のたびに警告が出るので、それを見たら
  # この let ブロックごと削除して `package` 行も消す。
  gitWithUpstream =
    lib.warnIf (lib.versionAtLeast pkgs.git.version "2.54")
      "modules/home/git.nix: nixpkgs の git が ${pkgs.git.version} になった。override ブロックを削除できる。"
      (
        pkgs.git.overrideAttrs (old: rec {
          version = "2.54.0";
          src = pkgs.fetchurl {
            url = "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
            sha256 = "sha256-9okWI2TBDeee+Jqo2/SHMesFfjTtu9IKylEM4BVGgaM=";
          };
          # 2.54 で upstream にマージ済み。重複適用を避けるため除外する。
          patches = builtins.filter (
            p: !(lib.hasSuffix "osxkeychain-define-build-targets-in-toplevel-Makefile.patch" (toString p))
          ) old.patches;
        })
      );
in
{
  programs.git = {
    enable = true;
    package = gitWithUpstream;

    # identity はリポジトリに持たない。~/.config/git/local.conf の [user] を読む。
    # 未設定のマシンではコミット時に落ちる (黙って別アドレスで打つより良い)。
    includes = [
      { path = "${host.homeDirectory}/.config/git/local.conf"; }
    ];

    settings = {
      credential.helper = "osxkeychain";
      ghq.root = "${host.homeDirectory}/project";
      init.defaultBranch = "main";
      core.ignorecase = false;
      core.editor = "nvim";
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };
}
