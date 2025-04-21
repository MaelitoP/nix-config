{ config, ... }:

let
  modules = [
    ./bat.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
    ./zsh.nix
    ./pkgs.nix
    ./starship.nix
    ./nix.nix
    ./direnv.nix
    ./fzf.nix
    ./tmux.nix
    ./fastfetch.nix
  ];
in
{
  imports = modules;
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
}
