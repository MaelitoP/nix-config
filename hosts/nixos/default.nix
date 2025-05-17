{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../common/default.nix ];
  
  config = {
    system.stateVersion = "24.05";
    
    # Set common NixOS settings
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    
    # Enable NetworkManager by default
    networking.networkmanager.enable = true;
    
    # Enable common services
    services.openssh.enable = true;
    
    # Enable X11 or Wayland
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;
    
    # Default user setup
    users.users.${config.machine.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      home = config.machine.home;
      shell = pkgs.zsh;
    };
    
    # Time zone and locale
    time.timeZone = "UTC";
    i18n.defaultLocale = "en_US.UTF-8";
    
    # Common system packages
    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      curl
    ];
  };
}