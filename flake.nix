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

      hmCommonModules = [
        ./home-manager/home/common.nix
        ./home-manager/home/mac.nix
      ];
    in
    {
      darwinConfigurations."HayatonoMacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin/default.nix
          ./darwin/profiles/personal.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = hmExtraSpecialArgs;
            home-manager.users.hayato = {
              imports = hmCommonModules;
            };
          }
        ];
      };

      # 互換: nix-darwin を使わずに HM 単独 switch する経路も残す
      homeConfigurations."hayato@HayatonoMacBook-Pro.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = hmCommonModules;
        extraSpecialArgs = hmExtraSpecialArgs;
      };
    };
}
