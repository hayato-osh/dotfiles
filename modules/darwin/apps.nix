# 全ホスト共通の GUI アプリ。片方だけのものは hosts/<profile>/default.nix へ。
# cask は GUI (.app) 専用 — CLI は packages.nix か mise.nix。
{
  homebrew.taps = [ "abue-ammar/tinycast" ];

  homebrew.casks = [
    "1password"
    "claude"
    "docker-desktop"
    "figma"
    "firefox"
    "ghostty"
    "gitify"
    "google-chrome"
    "google-japanese-ime"
    "notion"
    "obsidian"
    "postman"
    "slack"
    "abue-ammar/tinycast/tinycast"
    "visual-studio-code"
    "zed"
    "zoom"
  ];
}
