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
    { 
      home-manager,
      nix-darwin,
      nix-homebrew,
      sops-nix,
      catppuccin,
      ... 
    }:
    {
      darwinConfigurations = {
        devnull = nix-darwin.lib.darwinSystem {
          system = "x86_64-darwin";

          modules = [
            {
              nixpkgs.config.allowUnfree = true;
            }
            sops-nix.darwinModules.sops
            ./modules/darwin.nix
            home-manager.darwinModules.home-manager
            {
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
      };
    };
}
