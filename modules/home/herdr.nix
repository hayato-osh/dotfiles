{ pkgs, ... }:

{
  # バイナリは packages.nix (llm-agents)。~/.config/herdr には socket や session.json も
  # 置かれるので、ディレクトリごとではなく config.toml だけをリンクする。
  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;
    ui = {
      agent_panel_sort = "priority";
      sound.enabled = true;
      toast.delivery = "system";
    };
    theme = {
      name = "terminal"; # 配色は Ghostty の theme に従う
      auto_switch = false;
    };
  };
}
