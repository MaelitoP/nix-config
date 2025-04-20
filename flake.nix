{
  description = "maelito's config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    { 
      home-manager,
      nix-darwin,
      nix-homebrew,
      catppuccin,
      ... 
    }:
    {
      darwinConfigurations = {
        macbook-pro = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = [
            ./modules/darwin.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.maelito = {
                imports = [
                  ./modules
                  catppuccin.homeManagerModules.catppuccin
                ];
              };
            }
            nix-homebrew.darwinModules.nix-homebrew
          ];
        };
      };
    };
}
