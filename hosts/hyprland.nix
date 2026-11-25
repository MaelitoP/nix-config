{ config, pkgs, ... }:

{
  programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  };

  # Electron and Chromium apps pick X11 without this.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  home-manager.users.maelito.imports = [ ../modules/hyprland.nix ];
}
