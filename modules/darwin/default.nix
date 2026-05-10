{ config, lib, pkgs, ... }:

{
  imports = [
    ./macos-defaults.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = 6;
  system.primaryUser = "hayato";

  users.users.hayato = {
    name = "hayato";
    home = "/Users/hayato";
  };

  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts._3270
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # 移行期は誤削除を避けるため none。Step 10 で zap などに切替検討
      cleanup = "none";
    };
  };
}
