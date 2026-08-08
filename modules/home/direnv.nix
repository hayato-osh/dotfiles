{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;

    # flake / shell.nix の評価結果をキャッシュし、GC から守る。
    nix-direnv.enable = true;

    # `direnv: export +FOO ...` の毎回のログを黙らせる。
    silent = true;
  };
}
