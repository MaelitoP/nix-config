{ pkgs, ... }:
with pkgs;
[
  nodejs
  typescript
  typescript-language-server
  stylelint
  js-beautify
  lua-language-server
  bash-language-server
  nixd
  pyright
  intelephense
  ocamlPackages.ocaml-lsp
  haskell-language-server
  jdt-language-server
]
