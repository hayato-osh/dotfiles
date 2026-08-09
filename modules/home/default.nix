{ ... }:

{
  imports = [
    ./atuin.nix
    ./direnv.nix
    ./ghostty.nix
    ./git.nix
    ./mise.nix
    ./nh.nix
    ./nix-index.nix
    ./nvim
    ./packages.nix
    ./ssh.nix
    ./starship.nix
    ./zsh
  ];

  # Home Manager の互換性ピン。新しいリリースが出ても上げない。
  # 上げる場合は先に Home Manager の release notes を読むこと。
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
