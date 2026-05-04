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

  # ターミナル
  terminalTools = with pkgs; [
    tmux
  ];

  # Git / GitHub
  gitTools = with pkgs; [
    gh
    ghq
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
    ++ macTools;
}
