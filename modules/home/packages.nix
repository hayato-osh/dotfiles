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

  # Neovim が PATH から呼ぶ LSP / formatter / linter
  # nixfmt と statix は LazyVim の lang.nix extra が conform / nvim-lint に配線する。
  nvimTools = with pkgs; [
    lua-language-server
    nixd
    nixfmt
    statix
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

  programs.fzf = {
    enable = true;
    # Ctrl-R は atuin に渡す (modules/home/atuin.nix)。Ctrl-T / Alt-C は fzf のまま。
    historyWidget.zsh.command = "";
  };

  home.packages =
    modernCli
    ++ gitTools
    ++ nodeTools
    ++ serviceCli
    ++ mediaTools
    ++ agentTools
    ++ nvimTools
    ++ macTools;
}
