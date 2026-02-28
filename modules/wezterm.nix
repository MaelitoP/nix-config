{ pkgs, config, bar-wezterm-repo, ... }:

{
  # Mark the nix store path as a trusted git directory — libgit2 rejects
  # repos owned by a different user (root) without this.
  programs.git.extraConfig.safe.directory = "${bar-wezterm-repo}";

  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local mux = wezterm.mux

      local config = wezterm.config_builder()

      config.enable_tab_bar = false
      config.color_scheme = 'Catppuccin Mocha'

      -- Use file:// instead of https:// to avoid libgit2 SSL issues on some machines.
      -- The plugin hardcodes HTTPS URL-encoded paths for module resolution,
      -- so we prepend the correct source path for require() to find bar.* modules.
      package.path = "${bar-wezterm-repo}/plugin/?.lua;" .. package.path
      local bar = wezterm.plugin.require("file://${bar-wezterm-repo}")
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
