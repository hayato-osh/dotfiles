# server ホスト専用の常駐エージェント。スマホの Claude アプリから入る Remote Control と、
# Orca のヘッドレスランタイム。互いに依存させない (Orca が止まっても Remote Control は動く)。
{
  config,
  host,
  lib,
  ...
}:

let
  path = lib.concatStringsSep ":" [
    "/etc/profiles/per-user/${host.username}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
  log = name: "${host.homeDirectory}/Library/Logs/${name}.log";
in
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
      EnvironmentVariables.PATH = path;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = log "claude-remote-control";
      StandardErrorPath = log "claude-remote-control";
    };
  };

  # バイナリは cask (hosts/server)。/opt/homebrew/bin/orca はこのランチャーへの symlink。
  # LAN には出さず localhost だけで待つ。外からは Tailscale SSH の port forward で入る。
  launchd.agents.orca-serve = {
    enable = true;
    config = {
      ProgramArguments = [
        "/Applications/Orca.app/Contents/Resources/bin/orca"
        "serve"
        "--bind"
        "127.0.0.1"
        "--refuse-public"
        "--supervise"
      ];
      WorkingDirectory = host.homeDirectory;
      EnvironmentVariables.PATH = path;
      RunAtLoad = true;
      # --supervise が自前で再起動し、諦めたときは exit 0 する。そのときは launchd も止める。
      KeepAlive.SuccessfulExit = false;
      StandardOutPath = log "orca-serve";
      StandardErrorPath = log "orca-serve";
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
