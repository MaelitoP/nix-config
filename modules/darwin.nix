{ ... }:

{
  system.stateVersion = 5;

  users.users.maelito = {
    name = "maelito";
    home = "/Users/maelito";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  networking.computerName = "devnull";

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
          "/System/Cryptexes/App/System/Applications/Google Chrome.app"
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
