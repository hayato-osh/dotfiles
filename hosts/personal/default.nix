{ host, ... }:

{
  imports = [
    ../../modules/darwin
  ];

  nixpkgs.hostPlatform = host.system;

  homebrew = {
    # 共通分は modules/darwin/apps.nix。ここは個人機だけに入れるもの。
    casks = [
      "discord"
    ];

    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "RunCat" = 1429033973;
      "Xcode" = 497799835;
    };
  };
}
