{ config, lib, ... }:

with lib;

{
  options.machine = {
    username = mkOption {
      type = types.str;
      description = "Username";
    };
    realname = mkOption {
      type = types.str;
      default = config.machine.username;
      description = "Real name (defaults to username)";
    };
    home = mkOption {
      type = types.str;
      default = "/Users/${config.machine.username}";
      description = "Home directory";
    };
    platform = mkOption {
      type = types.str;
      description = "Platform (e.g. 'aarch64-darwin', 'x86_64-linux')";
    };
  };
  
  config = {
    nixpkgs.hostPlatform = config.machine.platform;
    nix.settings.trusted-users = [
      "root"
      config.machine.realname
    ];
  };
}