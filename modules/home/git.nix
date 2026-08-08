{
  host,
  lib,
  pkgs,
  ...
}:

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

      # 署名は SSH 鍵で行う。鍵の実体 (user.signingkey) と、1Password を使う
      # マシンだけに要る gpg.ssh.program は identity 同様 local.conf 側が持つ。
      commit.gpgsign = true;
      tag.gpgsign = true;
      gpg.format = "ssh";
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
