{ config, lib, pkgs, ... }:

{
  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  
  # Enable blueman applet
  services.blueman.enable = true;
  
  # Install bluetooth utilities
  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];
}