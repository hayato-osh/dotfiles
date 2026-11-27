# 常時稼働のホームサーバ (AC 給電のまま触らない MacBook)。Tailscale 経由でだけ触る。
# ホスト名は公開しないので、エントリは追跡外の hosts.local.nix に置く (README)。
{ host, ... }:

{
  imports = [
    ../../modules/darwin
  ];

  nixpkgs.hostPlatform = host.system;

  # 作業機の cask (workstation.nix) は入れない。Apple ID に紐づく masApps も無し。
  homebrew.casks = [
    "ghostty" # 画面共有で入ったときの非常用
  ];

  # Tailscale SSH はオープンソース版の tailscaled でしか動かない (App Store 版 / cask は不可)。
  # ログインは初回だけ手で `sudo tailscale up --ssh`。
  services.tailscale.enable = true;

  power = {
    sleep.computer = "never";
    # MacBook では未サポートの場合がある (systemsetup が黙って無視する)
    restartAfterPowerFailure = true;
  };

  # OS 更新の自動インストールで勝手に再起動させない
  system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
}
