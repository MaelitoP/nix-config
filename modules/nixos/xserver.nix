{ config, lib, pkgs, ... }:

{
  # Enable X11 and GNOME
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    
    # Keyboard layout
    layout = "us";
    xkbVariant = "";
    
    # Enable touchpad support
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        scrollMethod = "twofinger";
      };
    };
  };
  
  # Install common GNOME applications
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    wezterm
  ];
  
  # Enable Catppuccin GTK theme
  # This requires appropriate Catppuccin theme packages to be installed
}