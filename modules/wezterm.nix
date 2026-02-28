{ pkgs, config, bar-wezterm, ... }:

{
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local mux = wezterm.mux

      local config = wezterm.config_builder()

      config.enable_tab_bar = false
      config.color_scheme = 'Catppuccin Macchiato'

      local bar = wezterm.plugin.require("file://${bar-wezterm}")
      bar.apply_to_config(config)

      -- Fix Option key behavior for { and }
      config.send_composed_key_when_left_alt_is_pressed = true
      config.send_composed_key_when_right_alt_is_pressed = true

      -- Maximize window on startup
      wezterm.on("gui-startup", function(cmd)
        local _, _, window = mux.spawn_window(cmd or {})
        window:gui_window():maximize()
      end)

      return config
    '';
  };
}
