{ config, lib, ... }:

with lib;

let
  username = config.host.username;
  realname = config.host.realname or username;
  home = config.host.home or "/Users/${username}";
  platform = config.host.platform;
  extraCasks = config.host.extraCasks or [ ];
  extraBrews = config.host.extraBrews or [ ];
in
{
  options.host = {
    username = mkOption {
      type = types.str;
      description = "Username";
    };
    realname = mkOption {
      type = types.str;
      default = config.host.username;
      description = "Real name (defaults to username)";
    };
    home = mkOption {
      type = types.str;
      default = "/Users/${config.host.username}";
      description = "Home directory";
    };
    platform = mkOption {
      type = types.str;
      description = "Platform (e.g. 'aarch64-darwin')";
    };
    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra casks";
    };
    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra brews";
    };
  };

  config = {
    system.stateVersion = 5;
    system.primaryUser = username;

    users.users.maelito = {
      name = realname;
      home = home;
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    networking.computerName = "maelito";

    nixpkgs.hostPlatform = platform;
    nix.settings.trusted-users = [
      "root"
      realname
    ];

    programs.zsh.enable = true;

    nix-homebrew.enable = true;
    nix-homebrew.user = realname;
    nix-homebrew.autoMigrate = true;

    homebrew = {
      enable = true;
      onActivation.autoUpdate = false;
      taps = [ "wez/wezterm" ];
      brews = [ ] ++ extraBrews;
      casks = [
        "wezterm"
        "goland"
        "phpstorm"
        "pycharm"
        "intellij-idea"
        "slack"
        "google-chrome"
        "spotify"
        "1password"
      ] ++ extraCasks;
    };

    system = {
      defaults = {
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
  };
}
