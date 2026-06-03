{ ... }:

{
  programs.ghostty = {
    enable = true;

    package = null;

    enableZshIntegration = false;
    enableBashIntegration = false;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;

      maximize = true;
      window-save-state = "never";
      window-padding-x = 8;
      window-padding-y = 8;

      mouse-hide-while-typing = true;
      confirm-close-surface = false;

      macos-option-as-alt = true;

      keybind = [
        "alt+left=csi:1;3D"
        "alt+right=csi:1;3C"
        "ctrl+left=csi:1;5D"
        "ctrl+right=csi:1;5C"
      ];
    };
  };
}
