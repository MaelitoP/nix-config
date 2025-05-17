{ pkgs, config, ... }:

let
  commonUtils = with pkgs; [
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
    sops
    age
    jq
    htop
    neovim
    fd
    tmux
    uv
    openssl
    pkg-config
    claude-code
  ];

  darwinPkgs = if pkgs.stdenv.isDarwin then (
    with pkgs.darwin.apple_sdk; [
      frameworks.Security
      frameworks.CoreFoundation
      frameworks.SystemConfiguration
    ]
  ) else [];

  linuxPkgs = if pkgs.stdenv.isLinux then (
    with pkgs; [
      gnome.gnome-keyring
      xdg-utils
    ]
  ) else [];

  devTools = with pkgs; [
    clang
    stylua
    nixfmt-rfc-style
  ];

in {
  home.packages = commonUtils ++ devTools ++ (
    if pkgs.stdenv.isDarwin then darwinPkgs
    else if pkgs.stdenv.isLinux then linuxPkgs
    else []
  );
}
