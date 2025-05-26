{ pkgs, ... }:
with pkgs;
[
  ocamlPackages.ocaml
  ocamlPackages.dune_3
  ocamlformat
  opam
]
