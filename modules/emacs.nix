{
  config,
  lib,
  pkgs,
  ...
}:

{
  # On macOS Emacs is the Homebrew emacs-plus build, run by the launchd agent below.
  programs.emacs = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
    package = pkgs.emacs-pgtk;
  };
  services.emacs.enable = pkgs.stdenv.hostPlatform.isLinux;

  launchd.agents.emacs = {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/bin/emacs"
        "--fg-daemon"
      ];
      RunAtLoad = true;
      KeepAlive.Crashed = false;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.log";
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
