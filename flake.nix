{
  description = "maelito's config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      sops-nix,
      catppuccin,
      ...
    }:
    let
      mkDarwinConfig =
        {
          system,
          hostname,
          hostModule,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;

          modules = [
            {
              nixpkgs.config.allowUnfree = true;
            }
            sops-nix.darwinModules.sops
            hostModule
            home-manager.darwinModules.home-manager
            {
              home-manager.backupFileExtension = "bak";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.maelito = {
                imports = [
                  sops-nix.homeManagerModules.sops
                  ./modules
                  catppuccin.homeModules.catppuccin
                ];
              };
            }
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
    in
    {
      darwinConfigurations = {
        maelito-arm = mkDarwinConfig {
          system = "aarch64-darwin";
          hostname = "maelito-arm";
          hostModule = ./machines/maelito-arm.nix;
        };

        maelito-x86 = mkDarwinConfig {
          system = "x86_64-darwin";
          hostname = "maelito-x86";
          hostModule = ./machines/maelito-x86.nix;
        };
      };
    };
}
