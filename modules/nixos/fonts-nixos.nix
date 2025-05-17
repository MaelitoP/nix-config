{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
  
  fonts.fontconfig.enable = true;
}