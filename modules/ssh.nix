{ config, pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    userKnownHostsFile = "${config.xdg.dataHome}/ssh/known_hosts";
    matchBlocks = {
      "bastion1.mention.net bastion2.mention.net" = {
        extraOptions = {
          ProxyCommand = "none";
        };
      };
      
      "*.d.mention.net" = {
        extraOptions = {
          ProxyCommand = "none";
        };
      };
      
      "ssh_bastion" = {
        hostname = "bastion1.mention.net";
        user = "mael-lepetit";
      };
      
      "*.mention.net" = {
        user = "mention";
        extraOptions = {
          ProxyJump = "ssh_bastion";
        };
      };
      
      "*" = {
        identityFile = "${config.xdg.dataHome}/ssh/id_rsa";
        extraOptions = {
          AddKeysToAgent = "yes";
          UseKeychain = if pkgs.stdenv.isDarwin then "yes" else "no";
        };
      };
    };
  };
}
