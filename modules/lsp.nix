{ pkgs, ... }:
with pkgs;
[
  nodejs
  typescript
  typescript-language-server
  lua-language-server
  bash-language-server
  nixd
  pyright
  intelephense
  ocamlPackages.ocaml-lsp
]
