{ ... }:

{
  system.stateVersion = 5;

  users.users.pwnwriter = {
    name = "maelito";
    home = "/Users/maelito";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  networking.computerName = "agorapulse";

  nixpkgs.hostPlatform = "x86_64-darwin";
  nix.settings.trusted-users = [
    "root"
    "maelito"
  ];

  programs.zsh.enable = true;

  system = {
    defaults = {
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
