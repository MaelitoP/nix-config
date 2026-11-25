{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.host = {
    username = mkOption {
      type = types.str;
      description = "Username";
    };
    realname = mkOption {
      type = types.str;
      default = config.host.username;
      description = "Real name (defaults to username)";
    };
    home = mkOption {
      type = types.str;
      default = "${
        if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home"
      }/${config.host.username}";
      description = "Home directory";
    };
    platform = mkOption {
      type = types.str;
      description = "Platform (e.g. 'aarch64-darwin')";
    };
    extraHosts = mkOption {
      type = types.lines;
      default = "";
      description = "Extra /etc/hosts lines";
    };
  };

  config = {
    users.users.maelito = {
      name = config.host.realname;
      home = config.host.home;
    };

    nixpkgs.hostPlatform = config.host.platform;
    nix.settings.trusted-users = [
      "root"
      config.host.realname
    ];
    nix.settings.download-buffer-size = 268435456;

    programs.zsh.enable = true;
    programs.zsh.enableGlobalCompInit = false;

    # git rewrites https://github.com/ to ssh (modules/git.nix); without this a fresh machine fails every clone with "Host key verification failed".
    programs.ssh.knownHosts."github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

    fonts.packages = import ../modules/fonts.nix { inherit pkgs; };
  };
}
