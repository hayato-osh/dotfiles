# 作業機 (personal など) の GUI アプリ。hosts/<profile>/default.nix が import する。
# 常時稼働の server は import しない。cask は GUI (.app) 専用 — CLI は packages.nix か mise.nix。
{
  homebrew.taps = [ "abue-ammar/tinycast" ];

  homebrew.casks = [
    "claude"
    "docker-desktop"
    "figma"
    "firefox"
    "ghostty"
    "gitify"
    "google-chrome"
    "google-japanese-ime"
    "notion"
    "slack"
    "abue-ammar/tinycast/tinycast"
    "visual-studio-code"
    "zed"
    "zoom"
  ];
}
