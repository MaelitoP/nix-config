{ pkgs, lib, ... }:
let
  utils = with pkgs; [
    just
    bat

    curl
    direnv
    gh
    git
    ripgrep
    tree
    fastfetch
    sops
    age
    grpcurl
    jq
    htop
    neovim
    fd
    tmux
    uv
    openssl
    pkg-config
    claude-code-bin
    lnav
    granted
  ];

  fonts = (import ./fonts.nix { pkgs = pkgs; });

  development =
    with pkgs;
    [
      clang
      stylua
      nixfmt
    ]
    # macOS SDK - use apple-sdk for native compilation (CGO, etc.)
    ++ lib.optionals stdenv.isDarwin [
      apple-sdk_15
    ]
    ++ (import ./rust.nix { pkgs = pkgs; })
    ++ (import ./lsp.nix { pkgs = pkgs; })
    ++ (import ./go.nix { pkgs = pkgs; })
    ++ (import ./ocaml.nix { pkgs = pkgs; })
    ++ (import ./php.nix { pkgs = pkgs; });
in
{
  home.packages = utils ++ development ++ fonts;
}
