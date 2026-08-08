{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    yamlfmt.enable = true;
  };

  # *.zsh は除外 — shfmt が zsh 固有構文を bash として解釈して壊すため。
  settings.global.excludes = [
    "*.zsh"
    "*.lock"
  ];
}
