{ config, pkgs, ... }:

{
  imports = [ ./common.nix ];

  system.stateVersion = "26.11";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "maelito";
  networking.networkmanager.enable = true;
  networking.extraHosts = config.host.extraHosts;

  time.timeZone = "Europe/Paris";

  users.users.maelito = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  virtualisation.docker.enable = true;

  # mise and rustup download generic Linux binaries, which need a loader at the FHS path.
  programs.nix-ld.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ config.host.username ];
  };

  environment.systemPackages = with pkgs; [
    google-chrome
    spotify
    jetbrains.goland
    jetbrains.phpstorm
    jetbrains.pycharm
    jetbrains.rust-rover
    jetbrains.idea
    jetbrains.webstorm
    android-studio
  ];
}
