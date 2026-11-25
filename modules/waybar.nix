{ ... }:

{
  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 36;
      margin-top = 8;
      margin-left = 12;
      margin-right = 12;
      spacing = 8;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "cpu"
        "memory"
        "network"
        "pulseaudio"
        "tray"
      ];

      "hyprland/workspaces" = {
        format = "{id}";
        persistent-workspaces."*" = 5;
      };

      "hyprland/window" = {
        max-length = 60;
        separate-outputs = true;
      };

      clock = {
        format = "<span color='#cba6f7'></span>  {:%a %d %b  %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };

      cpu = {
        format = "<span color='#fab387'></span>  {usage}%";
        interval = 2;
      };

      memory = {
        format = "<span color='#a6e3a1'>󰍛</span>  {used:0.1f} GB";
        interval = 5;
      };

      network = {
        format-wifi = "<span color='#89b4fa'></span>  {essid}";
        format-ethernet = "<span color='#89b4fa'>󰈀</span>  {ipaddr}";
        format-disconnected = "<span color='#f38ba8'>󰖪</span>  offline";
        tooltip-format = "{ifname}  {ipaddr}  {signalStrength}%";
      };

      pulseaudio = {
        format = "<span color='#f5c2e7'>{icon}</span>  {volume}%";
        format-muted = "<span color='#f38ba8'>󰝟</span>  muted";
        format-icons.default = [
          ""
          ""
          ""
        ];
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      tray.spacing = 8;
    };

    # The colour names come from the catppuccin module, which prepends its palette to this sheet.
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        font-weight: bold;
        min-height: 0;
        border: none;
      }

      window#waybar {
        background: transparent;
      }

      #workspaces,
      #window,
      #clock,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        background: @base;
        color: @text;
        border: 2px solid @surface0;
        border-radius: 12px;
        padding: 0 14px;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        color: @overlay1;
        background: transparent;
        border-radius: 8px;
        padding: 0 8px;
        margin: 4px 2px;
      }

      #workspaces button.active {
        color: @base;
        background: @mauve;
      }

      #workspaces button:hover {
        color: @text;
        background: @surface1;
        box-shadow: none;
        text-shadow: none;
      }

      window#waybar.empty #window {
        background: transparent;
        border-color: transparent;
      }

      tooltip {
        background: @base;
        border: 2px solid @mauve;
        border-radius: 10px;
      }

      tooltip label {
        color: @text;
      }
    '';
  };
}
