{ config, pkgs, ... }:

{
  launchd.agents.emacs = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.emacs-macport}/bin/emacs"
        "--fg-daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.log";
      StandardErrorPath = "/tmp/emacs-daemon.log";
      EnvironmentVariables = {
        PATH = "${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
