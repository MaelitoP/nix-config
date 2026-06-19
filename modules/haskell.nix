{ pkgs, ... }:
with pkgs;
[
  ghc
  cabal-install
  ormolu
  hlint
  haskell.packages.ghc98.apply-refact
  haskellPackages.ghcid
]
