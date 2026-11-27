# server ホスト専用。スマホの Claude アプリから入る Remote Control セッションを常駐させる。
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

    スマホから Remote Control で入る入口セッション用。作業は入口セッション自身がやる。

    ## 仕事の進め方

    - 小さな作業や調べものは、その場で直接やる
    - 大きい開発作業や並列で進めたい作業は、タスクごとに git worktree を切ってそこで進める (subagent を使ってよい)
    - 変更はブランチを push して PR を出すところまで。マージはしない

    ## リポジトリの置き場

    - 個人のリポジトリは `~/project/` 配下
    - 副業のリポジトリは `~/side/` 配下
    - この 2 つを混ぜない。片方の作業でもう片方のコード・認証情報・設定を使わない
  '';
}
