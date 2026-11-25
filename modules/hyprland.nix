{ config, lib, ... }:

let
  wallpaper = "${config.home.homeDirectory}/Pictures/background.jpg";
  lua = lib.generators.mkLuaInline;
  bind = keys: action: {
    _args = [
      keys
      (lua "hl.dsp.${action}")
    ];
  };
  workspaces = builtins.genList (i: i + 1) 9;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland and its portal come from the NixOS module.
    package = null;
    portalPackage = null;
    configType = "lua";

    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      config = {
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
      };

      on._args = [
        "hyprland.start"
        (lua ''
          function()
            hl.exec_cmd("waybar")
          end'')
      ];

      bind = [
        (bind "SUPER + RETURN" ''exec_cmd("ghostty")'')
        (bind "SUPER + SPACE" ''exec_cmd("fuzzel")'')
        (bind "SUPER + Q" "window.close()")
        (bind "SUPER + V" ''window.float({ action = "toggle" })'')
        (bind "SUPER + SHIFT + E" "exit()")

        (bind "SUPER + H" ''focus({ direction = "left" })'')
        (bind "SUPER + L" ''focus({ direction = "right" })'')
        (bind "SUPER + K" ''focus({ direction = "up" })'')
        (bind "SUPER + J" ''focus({ direction = "down" })'')

        {
          _args = [
            "SUPER + mouse:272"
            (lua "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }
        {
          _args = [
            "SUPER + mouse:273"
            (lua "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }
      ]
      ++ map (n: bind "SUPER + ${toString n}" "focus({ workspace = ${toString n} })") workspaces
      ++ map (
        n: bind "SUPER + SHIFT + ${toString n}" "window.move({ workspace = ${toString n} })"
      ) workspaces;
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
