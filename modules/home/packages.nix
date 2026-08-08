{
  config,
  lib,
  pkgs,
  llm-agents,
  ...
}:

let
  # モダン CLI
  modernCli = with pkgs; [
    ast-grep
    bat
    eza
    fd
    jq
    ripgrep
  ];

  # Git / GitHub
  gitTools = with pkgs; [
    betterleaks
    gh
    ghq
    gnupg
    lazygit
  ];

  # JS/TS ランタイム
  nodeTools = with pkgs; [
    bun
  ];

  # SaaS / プラットフォーム CLI
  serviceCli = with pkgs; [
    _1password-cli
    stripe-cli
    supabase-cli
  ];

  # メディア処理
  mediaTools = with pkgs; [
    ffmpeg
    (tesseract.override {
      enableLanguages = [
        "eng"
        "jpn"
      ];
    })
  ];

  # AI コーディングエージェント (nixpkgs 未収録のため llm-agents.nix から)
  agentTools = [
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];

  # Language Server (LazyVim 自身の Lua 編集用)
  langServers = with pkgs; [
    lua-language-server
  ];

  # macOS 専用
  macTools = lib.optionals pkgs.stdenv.isDarwin (
    with pkgs;
    [
      mas
    ]
  );
in
{
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  home.packages =
    modernCli
    ++ gitTools
    ++ nodeTools
    ++ serviceCli
    ++ mediaTools
    ++ agentTools
    ++ langServers
    ++ macTools;
}
