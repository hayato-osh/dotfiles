{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home
  ];

  home.username = "hayato";
  home.homeDirectory = "/Users/hayato";

  home.packages = with pkgs; [
  ];

  home.file = {
  };
}
