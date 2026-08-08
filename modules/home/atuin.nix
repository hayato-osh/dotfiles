{
  programs.atuin = {
    enable = true;
    # HM の fzf 統合は mkOrder 910、atuin は既定順 (1000) なので atuin が後勝ちで Ctrl-R を取る。
    # fzf 側は Ctrl-T / Alt-C が残る。
    enableZshIntegration = true;

    # 上矢印は通常の履歴移動に残す。
    flags = [ "--disable-up-arrow" ];

    settings = {
      # 同期サーバには繋がない (ローカル SQLite のみ)。
      auto_sync = false;
      update_check = false;
    };
  };
}
