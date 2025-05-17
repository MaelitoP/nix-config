{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
    cargo-watch
    cargo-generate
  ];
}