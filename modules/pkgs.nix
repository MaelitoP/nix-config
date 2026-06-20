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
    claude-code
    lnav
    granted
    google-cloud-sdk
  ];

  development =
    with pkgs;
    [
      clang
      cmake
      stylua
      nixfmt
      tree-sitter
      shfmt
      shellcheck
      pandoc
      protobuf
    ]
    ++ lib.optionals stdenv.isDarwin [
      apple-sdk_15
    ]
    ++ (import ./rust.nix { pkgs = pkgs; })
    ++ (import ./lsp.nix { pkgs = pkgs; })
    ++ (import ./go.nix { pkgs = pkgs; })
    ++ (import ./ocaml.nix { pkgs = pkgs; })
    ++ (import ./php.nix { pkgs = pkgs; })
    ++ (import ./python.nix { pkgs = pkgs; })
    ++ (import ./haskell.nix { pkgs = pkgs; })
    ++ (import ./java.nix { pkgs = pkgs; });
in
{
  home.packages = utils ++ development;
}
