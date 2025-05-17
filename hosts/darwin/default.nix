{ config, lib, ... }:

with lib;

let
  username = config.machine.username;
  realname = config.machine.realname;
  extraCasks = config.machine.extraCasks or [ ];
in
{
  imports = [ ../common/default.nix ];
  
  options.machine.extraCasks = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "Extra Homebrew casks";
  };
  
  config = {
    system.stateVersion = 5;
    
    users.users.${username} = {
      name = realname;
      home = config.machine.home;
    };
    
    security.pam.services.sudo_local.touchIdAuth = true;
    
    networking.computerName = "maelito";
    
    programs.zsh.enable = true;
    
    nix-homebrew.enable = true;
    nix-homebrew.user = realname;
    nix-homebrew.autoMigrate = true;
    
    homebrew = {
      enable = true;
      onActivation.autoUpdate = false;
      taps = [ "wez/wezterm" ];
      brews = [ ];
      casks = [
        "wezterm"
        "goland"
        "phpstorm"
        "pycharm"
        "slack"
        "google-chrome"
        "spotify"
        "1password"
      ] ++ extraCasks;
    };
    
    system.defaults = {
      dock = {
        tilesize = 20;
        orientation = "right";
        persistent-apps = [
          "/Applications/WezTerm.app"
          "/Applications/PhpStorm.app"
          "/Applications/GoLand.app"
          "/Applications/PyCharm.app"
          "/Applications/Slack.app"
          "/Applications/Google Chrome.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Mail.app"
        ];
      };

      CustomUserPreferences = {
        "com.apple.screencapture" = {
          location = "~/Documents/screenshots";
          type = "png";
        };
      };

      NSGlobalDomain = {
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };

      SoftwareUpdate = {
        AutomaticallyInstallMacOSUpdates = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
    };
  };
}