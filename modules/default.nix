{ pkgs, config, lib, ... }:

let
  # Detect platform
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  
  # Common modules for all platforms
  commonModules = [
    ./core
    ./dev
    ./pkgs
  ];
  
  # Platform-specific modules
  platformModules = if isDarwin then [
    ./darwin
  ] else if isLinux then [
    ./nixos
  ] else [];

in {
  imports = commonModules ++ platformModules;
  
  # Common settings for all platforms
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
  
  # Platform-specific data directories
  xdg.dataHome = if isDarwin then 
    "${config.home.homeDirectory}/.local/share"
  else if isLinux then
    "${config.home.homeDirectory}/.local/share"
  else
    "${config.home.homeDirectory}/.local/share";
}