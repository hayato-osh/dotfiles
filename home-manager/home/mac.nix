{ config, pkgs, ... }:

{
  home.username = "hayato";
  home.homeDirectory = "/Users/hayato";

  home.packages = with pkgs; [
  ];

  home.file = {
  };
}
