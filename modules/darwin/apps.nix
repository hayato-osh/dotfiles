# 全ホスト共通の GUI アプリ。片方だけのものは hosts/<profile>/default.nix へ。
# cask は GUI (.app) 専用 — CLI は packages.nix か mise.nix。
{
  homebrew.casks = [
    "1password"
    "claude"
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
    "zed"
    "zoom"
  ];
}
