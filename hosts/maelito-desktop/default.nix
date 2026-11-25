{ config, pkgs, ... }:

{
  imports = [
    ../nixos.nix
    ../hyprland.nix
    ./disk.nix
  ];

  host = {
    username = "maelito";
    platform = "x86_64-linux";
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # FACEIT on the Windows side needs Secure Boot on, so NixOS boots through lanzaboote,
  # which signs the boot files with the machine's own keys and replaces the systemd-boot module.
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    autoGenerateKeys.enable = true;
  };
  environment.systemPackages = [ pkgs.sbctl ];

  # Windows keeps the hardware clock in local time; without this each OS shifts the other's clock.
  time.hardwareClockInLocalTime = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
