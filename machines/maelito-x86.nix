{ ... }:

{
  system.stateVersion = 5;

  users.users.maelito = {
    name = "maelito";
    home = "/Users/maelito";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  networking.computerName = "maelito";

  nixpkgs.hostPlatform = "x86_64-darwin";
  nix.settings.trusted-users = [
    "root"
    "maelito"
  ];

  programs.zsh.enable = true;

  nix-homebrew.enable = true;
  nix-homebrew.user = "maelito";
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
      "chromium"
      "spotify"
    ];
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
}
