{ host, ... }:

{
  programs.ssh = {
    enable = true;

    # HM が暗黙に入れる旧既定値は将来削除される (残すと switch のたびに warning)。
    # 必要な値だけ下の settings で明示する。
    enableDefaultConfig = false;

    # マシン固有の設定を逃がすための口。追跡外なので無くてもよく、ssh は存在
    # しない Include を黙って無視する (`ssh -G` で確認済み)。
    includes = [ "${host.homeDirectory}/.ssh/config.local" ];

    # キーは OpenSSH のディレクティブ名をそのまま使う (matchBlocks は非推奨)。
    settings."*" = {
      # 認証にも Secure Enclave の鍵を使う。秘密鍵は取り出せないので、
      # ディスク上の id_secure_enclave は鍵そのものではなくハンドル。
      SecurityKeyProvider = "/usr/lib/ssh-keychain.dylib";
      IdentityFile = "${host.homeDirectory}/.ssh/id_secure_enclave";
    };
  };
}
