{
  host,
  pkgs,
  ...
}:

{
  imports = [
    ./apps.nix
    ./macos-defaults.nix
  ];

  # nixpkgs.hostPlatform はホスト固有なので hosts/<profile>/default.nix 側で設定する。
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # 放置すると /nix/store が数ヶ月で数十 GB になるので自動 GC する。
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 3;
      Minute = 15;
    };
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  system.stateVersion = 6;
  system.primaryUser = host.username;

  # これが無いと Home Manager が `home.homeDirectory ... null` で落ちる。
  users.users.${host.username} = {
    name = host.username;
    home = host.homeDirectory;
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
