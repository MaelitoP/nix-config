{ pkgs, ... }:
with pkgs;
[
  rustup
  cargo-watch
  (cargo-generate.overrideAttrs { doCheck = false; })
]
