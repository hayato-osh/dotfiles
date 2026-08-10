{
  host,
  lib,
  pkgs,
  ...
}:

let
  # 署名鍵は Secure Enclave の中にあり、Apple の ssh-keychain.dylib 経由でしか
  # 触れない。git は gpg.ssh.program を環境変数なしで呼ぶので、provider の指定を
  # ラッパーで注入する。ssh-keygen は nixpkgs 版ではなく /usr/bin を使う
  # (dylib が Apple 製で、対応するのは OS 同梱の ssh-keygen だけ)。
  ssh-sign = pkgs.writeShellScriptBin "ssh-sign" ''
    export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
    exec /usr/bin/ssh-keygen "$@"
  '';
in
{
  programs.git = {
    enable = true;

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

      # 署名は SSH 鍵で行う。鍵はマシンごとに違う (Secure Enclave の外に出せず
      # 複製もできない) ので、user.signingkey は identity 同様 local.conf 側。
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.program = lib.getExe ssh-sign;
      gpg.ssh.allowedSignersFile = "${host.homeDirectory}/.config/git/allowed_signers";

      # difftastic は difftool 側だけに挿す。programs.difftastic.git.enable は
      # delta と HM の assertion で排他になるため使わず、ここで手書きする。
      diff.tool = "difftastic";
      difftool.prompt = false;
      "difftool \"difftastic\"".cmd = "${lib.getExe pkgs.difftastic} \"$LOCAL\" \"$REMOTE\"";
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };

  # パッケージだけ入れる。git への配線は上の settings が持つ。
  programs.difftastic = {
    enable = true;
    git.enable = false;
  };

  programs.delta = {
    enable = true;
    # core.pager / interactive.diffFilter を delta が握る。`git diff` はこちら。
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
    };
  };
}
