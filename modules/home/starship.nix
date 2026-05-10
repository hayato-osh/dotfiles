{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      command_timeout = 1000;

      character = {
        error_symbol = "[❯](bold red)";
        success_symbol = "[❯](bold green)";
      };

      git_status = {
        conflicted = "💥";
        ahead = "🏎💨";
        behind = "😰";
        diverged = "😵";
        untracked = "🌚‍";
        stashed = "📦";
        modified = "📝";
        staged = "🔦";
        renamed = "🏷";
        deleted = "🗑";
      };

      battery = {
        full_symbol = "🔋 ";
        charging_symbol = "⚡️ ";
        discharging_symbol = "💀 ";
      };
    };
  };
}
