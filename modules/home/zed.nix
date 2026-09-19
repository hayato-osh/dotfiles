{
  programs.zed-editor = {
    enable = true;
    # バイナリは cask (modules/darwin/apps.nix)。HM は設定だけ書く。
    package = null;

    extensions = [ "tokyo-night" ];

    # switch のたびに既存の settings.json へ上書きマージされる。
    # ここに無いキーは Zed の UI から変えても残る。
    userSettings = {
      autosave = "on_focus_change";
      base_keymap = "Cursor";
      vim_mode = false;
      ui_font_size = 16;
      buffer_font_size = 15;
      # 内蔵ターミナルも未指定ならこれを継ぐ
      buffer_font_family = "Hack Nerd Font Mono";
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Tokyo Night Storm";
      };
      tabs = {
        git_status = true;
      };
      terminal = {
        copy_on_select = true;
      };
      icon_theme = {
        mode = "dark";
        light = "Zed (Default)";
        dark = "Zed (Default)";
      };
      diff_view_style = "split";
      cli_default_open_behavior = "new_window";
      git_panel = {
        group_by = "staging";
        tree_view = true;
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      agent_servers.claude-acp.type = "registry";
    };
  };
}
