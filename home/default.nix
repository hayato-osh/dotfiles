# ユーザー × ホストの組み立て層。
# ホスト固有の値は flake.nix の `hosts` attrset から `host` として渡ってくるので、
# このファイルにマシン固有のリテラルを書かない。
{ host, ... }:

{
  imports = [
    ../modules/home
  ];

  home.username = host.username;
  home.homeDirectory = host.homeDirectory;
}
