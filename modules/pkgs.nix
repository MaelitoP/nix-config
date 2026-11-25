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
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      apple-sdk_15
    ]
    # On macOS these come from Homebrew, and Claude Code from its own installer.
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      mise
      claude-code
      scaleway-cli
      ghz
      mysql84
      qemu
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
