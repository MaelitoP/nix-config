{
  description = "maelito's config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # cargo-watch fails to link on newer nixpkgs (cctools ld crashes on
    # mac-notification-sys, aarch64-darwin). Pin it to the last rev that builds.
    # https://github.com/NixOS/nixpkgs/issues/226031
    nixpkgs-cargo-watch.url = "github:nixos/nixpkgs/d99b013d5d1931ad77fe3912ed218170dec5d9a4";

    # Nixpkgs 26.11 dropped x86_64-darwin (including from lib.platforms.darwin,
    # which home-manager and nix-darwin consult), so the Intel host needs the
    # whole stack on the 26.05 branches, security-fixed until the end of 2026.
    nixpkgs-x86.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    home-manager-x86 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-x86";
    };
    nix-darwin-x86 = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-x86";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config.url = "github:MaelitoP/nvim-config";
    emacs-config.url = "github:MaelitoP/emacs-config";
    catppuccin.url = "github:catppuccin/nix";

    bar-wezterm = {
      url = "github:adriankarlen/bar.wezterm";
      flake = false;
    };
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
          nixpkgs ? inputs.nixpkgs,
          home-manager ? inputs.home-manager,
          nix-darwin ? inputs.nix-darwin,
        }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Build a git-initialized copy of bar.wezterm plugin source.
          # Wezterm uses libgit2 to clone plugins — file:// avoids HTTPS/SSL issues,
          # and the .git directory is required for libgit2 to recognize it as a repo.
          bar-wezterm-repo =
            pkgs.runCommand "bar-wezterm-repo"
              {
                nativeBuildInputs = [ pkgs.git ];
              }
              ''
                export HOME=$(mktemp -d)
                export GIT_AUTHOR_NAME="nix"
                export GIT_AUTHOR_EMAIL="nix@localhost"
                export GIT_COMMITTER_NAME="nix"
                export GIT_COMMITTER_EMAIL="nix@localhost"
                cp -r ${inputs.bar-wezterm} $out
                chmod -R u+w $out
                cd $out
                git init
                git add .
                git commit -m "init"
              '';
        in
        nix-darwin.lib.darwinSystem {
          inherit system;

          modules = [
            {
              nixpkgs.pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
                overlays = [
                  (final: prev: {
                    cargo-watch = inputs.nixpkgs-cargo-watch.legacyPackages.${system}.cargo-watch;
                  })
                ];
              };
            }
            (
              { pkgs, ... }:
              {
                fonts.packages = import ./modules/fonts.nix { inherit pkgs; };
              }
            )
            sops-nix.darwinModules.sops
            hostModule
            home-manager.darwinModules.home-manager
            {
              home-manager.backupFileExtension = "bak";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit bar-wezterm-repo; };
              home-manager.users.maelito = {
                imports = [
                  sops-nix.homeManagerModules.sops
                  ./modules
                  catppuccin.homeModules.catppuccin
                  inputs.nvim-config.homeManagerModules.nvim-config
                  inputs.emacs-config.homeManagerModules.emacs-config
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
          hostModule = ./hosts/maelito-arm.nix;
        };

        maelito-x86 = mkDarwinConfig {
          system = "x86_64-darwin";
          hostname = "maelito-x86";
          hostModule = ./hosts/maelito-x86.nix;
          nixpkgs = inputs.nixpkgs-x86;
          home-manager = inputs.home-manager-x86;
          nix-darwin = inputs.nix-darwin-x86;
        };
      };
    };
}
