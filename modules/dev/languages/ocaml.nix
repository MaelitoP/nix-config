{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ocamlPackages.ocaml
    ocamlPackages.dune_3
    ocamlformat
  ];
}