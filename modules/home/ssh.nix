{ host, ... }:

{
  programs.ssh = {
    enable = true;

    # HM が暗黙に入れる旧既定値は将来削除される (残すと switch のたびに warning)。
    # 必要な値だけ下の settings で明示する。
    enableDefaultConfig = false;

    # 1Password の SSH agent を使うかはマシンによる (IdentityAgent)。git の
    # identity と同じく追跡外の config.local が持つ。ssh は先勝ちで解決するので
    # Include はファイル先頭に置かれる必要があり、HM がそう並べる。
    includes = [ "${host.homeDirectory}/.ssh/config.local" ];

    # キーは OpenSSH のディレクティブ名をそのまま使う (matchBlocks は非推奨)。
    settings."*" = {
      # 1Password を入れられないマシン向け。鍵を一度 agent に載せ、パスフレーズは
      # Keychain に預ける。これが無いと再起動のたびにパスフレーズを聞かれる。
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
    };
  };
}
