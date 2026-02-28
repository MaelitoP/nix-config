{ config, ... }:

let
  modules = [
    ./pkgs.nix
    ./bat.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
    ./zsh.nix
    ./starship.nix
    ./nix.nix
    ./direnv.nix
    ./fzf.nix
    ./tmux.nix
    ./fastfetch.nix
    ./claude.nix
    ./wezterm.nix
  ];
in
{
  imports = modules;
  xdg.dataHome = "${config.home.homeDirectory}/.local/share";
  programs.home-manager.enable = true;
  home.stateVersion = "24.05";
}
