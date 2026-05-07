{ config, lib, pkgs, ... }:

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

  # ターミナル multiplexer (tmux からの乗り換え)
  terminalTools = with pkgs; [
    zellij
  ];

  # Git / GitHub
  gitTools = with pkgs; [
    gh
    ghq
    lazygit
    git-secrets
    gnupg
  ];

  # JS/TS ランタイム
  nodeTools = with pkgs; [
    bun
  ];

  # SaaS / プラットフォーム CLI
  serviceCli = with pkgs; [
    stripe-cli
    supabase-cli
  ];

  # メディア処理
  mediaTools = with pkgs; [
    ffmpeg
    (tesseract.override { enableLanguages = [ "eng" "jpn" ]; })
  ];

  # Language Server (LazyVim 自身の Lua 編集用)
  langServers = with pkgs; [
    lua-language-server
  ];

  # macOS 専用
  macTools = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
    mas
  ]);
in
{
  programs.zoxide.enable = true;
  programs.fzf.enable = true;

  home.packages =
    modernCli
    ++ terminalTools
    ++ gitTools
    ++ nodeTools
    ++ serviceCli
    ++ mediaTools
    ++ langServers
    ++ macTools;
}
