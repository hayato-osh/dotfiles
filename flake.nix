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

    # nixpkgs 未収録の AI コーディングエージェント系 CLI (herdr など)
    #
    # nixpkgs を follows させないのは意図的。この flake の packages 出力は
    # 全パッケージを一括評価するため、上流が pin した nixpkgs を差し替えると
    # herdr と無関係なパッケージ (agent-browser の pnpm_11 など) の依存欠落で
    # 評価ごと落ちる。上流のバイナリキャッシュも rev 一致時しか効かない。
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    { nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      hmExtraSpecialArgs = {
        inherit (inputs) zsh-autosuggestions zsh-completions zsh-syntax-highlighting lazyvim llm-agents;
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
