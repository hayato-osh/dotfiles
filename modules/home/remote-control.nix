# server ホスト専用。スマホの Claude アプリから入る Remote Control セッションを常駐させる。
# Orca が止まっていても動くよう、Orca には依存させない。
{
  config,
  host,
  lib,
  ...
}:

lib.mkIf (host.profile == "server") {
  # claude 本体は mise (mise.nix) が持つので、mise exec 経由で解決する。
  launchd.agents.claude-remote-control = {
    enable = true;
    config = {
      ProgramArguments = [
        (lib.getExe config.programs.mise.package)
        "exec"
        "--"
        "claude"
        "remote-control"
        "--name"
        "sub"
      ];
      WorkingDirectory = host.homeDirectory;
      EnvironmentVariables.PATH = lib.concatStringsSep ":" [
        "/etc/profiles/per-user/${host.username}/bin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
        "/opt/homebrew/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${host.homeDirectory}/Library/Logs/claude-remote-control.log";
      StandardErrorPath = "${host.homeDirectory}/Library/Logs/claude-remote-control.log";
    };
  };

  # 入口セッション (WorkingDirectory = ~) が読む指示。
  home.file."CLAUDE.md".text = ''
    # 入口セッション向けの指示

    このファイルはスマホから Remote Control で入る入口セッション用。Orca の worker として起動されている場合は従わず、渡されたタスクだけをこなす。

    ## 仕事の振り分け

    - 大きい開発作業・並列で進めたい作業・PR の見張りは Orca に渡す。`orca orchestration` で worker か bot を立てる
    - 小さな作業や調べものは自分で直接やる
    - Orca が応答しないときは待たない。git worktree を切って自分で作業を進める

    ## リポジトリの置き場

    - 個人のリポジトリは `~/project/` 配下
    - 副業のリポジトリは `~/side/` 配下
    - この 2 つを混ぜない。片方の作業でもう片方のコード・認証情報・設定を使わない
  '';
}
