{ lib, ... }:

let
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
  imports = [ ./waybar.nix ];

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
          gaps_in = 5;
          gaps_out = 12;
          border_size = 2;
          col = {
            active_border = {
              colors = [
                "rgba(cba6f7ff)"
                "rgba(89b4faff)"
              ];
              angle = 45;
            };
            inactive_border = "rgba(313244ff)";
          };
        };

        decoration = {
          rounding = 12;
          blur = {
            enabled = true;
            size = 6;
            passes = 3;
          };
          shadow = {
            enabled = true;
            range = 12;
            render_power = 3;
          };
        };
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

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=13";
        terminal = "ghostty -e";
        width = 40;
        lines = 10;
        horizontal-pad = 20;
        vertical-pad = 16;
        inner-pad = 10;
      };
      border = {
        width = 2;
        radius = 12;
      };
    };
  };

  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      border-size = 2;
      border-radius = 12;
      padding = "12";
      default-timeout = 5000;
    };
  };
}
