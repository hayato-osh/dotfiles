{ config, lib, pkgs, ... }:

{
  homebrew = {
    casks = [
      "1password"
      "1password-cli"
      "brave-browser"
      "claude-code"
      "deepl"
      "discord"
      "docker-desktop"
      "firefox"
      "ghostty"
      "google-chrome"
      "google-japanese-ime"
      "notion"
      "obsidian"
      "postman"
      "raycast"
      "slack"
      "visual-studio-code"
      "zoom"
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
