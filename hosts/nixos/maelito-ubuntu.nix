{ ... }:

{
  imports = [ ./default.nix ];

  machine = {
    username = "maelito";
    realname = "maelito";
    home = "/home/maelito";
    platform = "x86_64-linux";
  };
  
  # Ubuntu-specific configurations
  networking.hostName = "maelito-ubuntu";
  
  # Example: GPU drivers for NVIDIA
  # services.xserver.videoDrivers = [ "nvidia" ];
  
  # Example: Enable fingerprint reader
  # services.fprintd.enable = true;
}