{ pkgs, ... }:
with pkgs;
[
  ocamlPackages.ocaml
  ocamlPackages.dune_3
  ocamlPackages.ocaml-lsp
  ocamlformat
  opam
]
