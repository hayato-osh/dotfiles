{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "22.17.0";
        "npm:@anthropic-ai/claude-code" = "latest";
        "npm:@google/gemini-cli" = "latest";
        python = "latest";
      };

      settings = {
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };
}
