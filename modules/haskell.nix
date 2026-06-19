{ pkgs, ... }:
with pkgs;
[
  ghc
  cabal-install
  ormolu
  hlint
  haskellPackages.apply-refact
  haskellPackages.ghcid
]
