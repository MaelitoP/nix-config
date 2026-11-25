{ config, ... }:

let
  wallpaper = "${config.home.homeDirectory}/Pictures/background.jpg";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland and its portal come from the NixOS module.
    package = null;
    portalPackage = null;
    configType = "hyprlang";

    settings = {
      "$mod" = "SUPER";

      monitor = ",preferred,auto,1";

      exec-once = [ "waybar" ];

      input = {
        kb_layout = "us";
        kb_variant = "intl";
        repeat_delay = 250;
        repeat_rate = 40;
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
      };

      decoration.rounding = 8;

      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Space, exec, fuzzel"
        "$mod, Q, killactive"
        "$mod, F, fullscreen"
        "$mod, V, togglefloating"
        "$mod SHIFT, E, exit"

        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
      ]
      ++ builtins.concatMap (n: [
        "$mod, ${toString n}, workspace, ${toString n}"
        "$mod SHIFT, ${toString n}, movetoworkspace, ${toString n}"
      ]) (builtins.genList (i: i + 1) 9);

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  programs.waybar.enable = true;
  programs.fuzzel.enable = true;
  services.mako.enable = true;

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      wallpaper = [
        {
          monitor = "";
          path = wallpaper;
        }
      ];
    };
  };
}
