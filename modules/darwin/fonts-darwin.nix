{ pkgs, ... }:
with pkgs;
{
  home.packages = [
    nerd-fonts.jetbrains-mono
  ];
}