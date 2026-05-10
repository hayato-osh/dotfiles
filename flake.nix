{
  description = "Home Manager + nix-darwin configuration of hayato";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sheldon plugins (sourced declaratively, not at runtime)
    zsh-autosuggestions = {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };
    zsh-completions = {
      url = "github:zsh-users/zsh-completions";
      flake = false;
    };
    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };

    # LazyVim を宣言的に管理
    lazyvim.url = "github:pfassina/lazyvim-nix";
  };

  outputs =
    { nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      hmExtraSpecialArgs = {
        inherit (inputs) zsh-autosuggestions zsh-completions zsh-syntax-highlighting lazyvim;
      };
    in
    {
      darwinConfigurations."HayatonoMacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/HayatonoMacBook-Pro
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = hmExtraSpecialArgs;
            home-manager.users.hayato.imports = [ ./home/hayato ];
          }
        ];
      };
    };
}
