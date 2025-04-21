{ pkgs, ... }:
let
  utils = with pkgs; [
    just
    bat
    coreutils
    curl
    direnv
    gh
    git
    ripgrep
    tree
    fastfetch

    jq
    htop

    neovim
    fd
    tmux
    uv

    openssl
    pkg-config
  ];

  darwin =
    with pkgs.darwin.apple_sdk;
    [

      frameworks.Security
      frameworks.CoreFoundation
      frameworks.SystemConfiguration
    ]

    ++ (import ./fonts.nix { pkgs = pkgs; });

  development =
    with pkgs;
    [
      clang
      stylua
      nixfmt-rfc-style
    ]

    ++ (import ./rust.nix { pkgs = pkgs; })
    ++ (import ./lsp.nix { pkgs = pkgs; })
    ++ (import ./go.nix { pkgs = pkgs; });
in
{
  home.packages = utils ++ development ++ darwin;
}
