{ config, pkgs, lib, ... }:

let
  pinentry =
    if pkgs.stdenv.isDarwin then
      pkgs.pinentry_mac
    else
      pkgs.pinentry-curses;

in {
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
  };

  home.packages = [ pinentry ];

  home.file."${config.xdg.dataHome}/gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pinentry}/bin/${pinentry.pname}
  '';
}
