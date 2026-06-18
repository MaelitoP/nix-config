{ pkgs, ... }:
with pkgs;
[
  ocamlPackages.ocaml
  ocamlPackages.dune_3
  ocamlPackages.ocaml-lsp
  ocamlPackages.utop
  ocamlPackages.ocp-indent
  ocamlPackages.merlin
  ocamlformat
  opam
]
