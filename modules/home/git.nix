{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Fastman";
        email = "gabayt0_0@icloud.com";
      };
      credential.helper = "osxkeychain";
      ghq.root = "/Users/hayato/project";
      init.defaultBranch = "main";
      core.ignorecase = false;
    };

    ignores = [
      "**/.claude/settings.local.json"
    ];
  };
}
