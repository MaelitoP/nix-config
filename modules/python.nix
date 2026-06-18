{ pkgs, ... }:
with pkgs;
[
  black
  isort
  python3Packages.pyflakes
  python3Packages.pytest
]
