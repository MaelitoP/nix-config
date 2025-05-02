{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:

let
  pinentry = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;

in
{
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
  };

  home.packages = [
    pinentry
    pkgs.gnupg
  ];

  home.file."${config.xdg.dataHome}/gnupg/gpg-agent.conf".text = ''
    enable-ssh-support
    pinentry-program ${pinentry}/bin/${pinentry.pname}
  '';

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets.gpg_private_key = {
      sopsFile = ../secrets/default.yaml;
      path = "${config.xdg.dataHome}/gnupg/private.key";
    };

    secrets.gpg_passphrase = {
      sopsFile = ../secrets/default.yaml;
      path = "${config.xdg.dataHome}/gnupg/passphrase.txt";
    };
  };
}
