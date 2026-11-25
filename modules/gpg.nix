{
  config,
  pkgs,
  lib,
  sops-nix,
  ...
}:

let
  pinentry = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-qt;

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

  # Outside the graphical session pinentry falls back to a terminal prompt, which needs the tty.
  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isLinux "export GPG_TTY=$(tty)";

  home.file."${config.xdg.dataHome}/gnupg/gpg-agent.conf".text = ''
    enable-ssh-support
    pinentry-program ${pinentry}/bin/${pinentry.pname}
  '';

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets.gpg_private_key = {
      sopsFile = ../secrets/gpg.yaml;
      path = "${config.xdg.dataHome}/gnupg/private.key";
    };

    secrets.gpg_passphrase = {
      sopsFile = ../secrets/gpg.yaml;
      path = "${config.xdg.dataHome}/gnupg/passphrase.txt";
    };
  };
}
