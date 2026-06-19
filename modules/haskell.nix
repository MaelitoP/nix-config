{ pkgs, ... }:
with pkgs;
[
  ghc
  cabal-install
  ormolu
  hlint
  haskellPackages.ghcid
]
