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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixpkgs 未収録の AI コーディングエージェント系 CLI (herdr など)
    #
    # nixpkgs を follows させないのは意図的。この flake の packages 出力は
    # 全パッケージを一括評価するため、上流が pin した nixpkgs を差し替えると
    # herdr と無関係なパッケージ (agent-browser の pnpm_11 など) の依存欠落で
    # 評価ごと落ちる。上流のバイナリキャッシュも rev 一致時しか効かない。
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      treefmt-nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      # マシン固有の値の唯一の置き場。新ホストは 1 エントリ + hosts/<profile>/ を足す。
      publicHosts = {
        personal = {
          # `scutil --get LocalHostName` の出力
          hostName = "HayatonoMacBook-Pro";
          system = "aarch64-darwin";
          username = "hayato";
        };
      };

      # 公開しないホストは追跡外の hosts.local.nix に置く (書き方は README)。
      # git 追跡外なので `--flake .` からは見えない。読ませるマシンは `--flake path:.`。
      localHosts = if builtins.pathExists ./hosts.local.nix then import ./hosts.local.nix else { };

      hosts = publicHosts // localHosts;

      mkDarwin =
        profile: host:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs;
            host = host // {
              inherit profile;
              homeDirectory = "/Users/${host.username}";
            };
          };
          modules = [
            ./hosts/${profile}
            home-manager.darwinModules.home-manager
            (
              { config, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = {
                  inherit (inputs)
                    zsh-autosuggestions
                    zsh-completions
                    zsh-syntax-highlighting
                    lazyvim
                    llm-agents
                    ;
                  inherit (config._module.specialArgs) host;
                };
                home-manager.users.${host.username}.imports = [ ./home ];
              }
            )
          ];
        };

      darwinSystems = lib.mapAttrs mkDarwin hosts;

      # darwin 以外も出すのは、Linux runner でフォーマット検査をビルドするため。
      fmtSystems = [
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs fmtSystems;
      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      # 論理名と実ホスト名の両方を生やす (一致していれば `--flake .` だけで通る)。
      darwinConfigurations =
        darwinSystems
        // lib.mapAttrs' (profile: host: lib.nameValuePair host.hostName darwinSystems.${profile}) hosts;

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # darwin 構成は checks に入れない。lazyvim-nix の IFD が Linux runner で
      # 実行できず --no-build も通らないため。検証は lint.yaml の macOS ジョブ。
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
