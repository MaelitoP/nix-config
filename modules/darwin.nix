{ ... }:

{
  system.stateVersion = 5;

  users.users.maelito = {
    name = "mael.lepetit";
    home = "/Users/mael.lepetit";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  networking.computerName = "devnull";

  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.settings.trusted-users = [
    "root"
    "mael.lepetit"
  ];

  programs.zsh.enable = true;

  nix-homebrew.enable = true;
  nix-homebrew.user = "mael.lepetit";
  nix-homebrew.autoMigrate = true;

  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    taps = [
      "wez/wezterm"
    ];
    brews = [ ];
    casks = [
      "wezterm"
      "goland"
      "phpstorm"
      "pycharm"
      "slack"
      "google-chrome"
      "spotify"
    ];
  };

  system = {
    defaults = {
      dock = {
        tilesize = 20;
        orientation = "left";
        autohide = true;
        persistent-apps = [
          "/System/Applications/Wezterm.app"
          "/System/Applications/PhpStorm.app"
          "/System/Applications/GoLand.app"
          "/System/Applications/PyCharm.app"
          "/System/Applications/Slack.app"
          "/System/Applications/Chromium.app"
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
        _HIHideMenuBar = true;
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
