{ host, ... }:

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
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };
}
