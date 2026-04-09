{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops.secrets.id_rsa = {
    sopsFile = ../secrets/ssh.yaml;
    path = "${config.xdg.dataHome}/ssh/id_rsa";
  };

  sops.secrets.id_rsa_pub = {
    sopsFile = ../secrets/ssh.yaml;
    path = "${config.xdg.dataHome}/ssh/id_rsa.pub";
  };

  sops.secrets.id_ed25519_scaleway = {
    sopsFile = ../secrets/ssh.yaml;
    path = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway";
  };

  sops.secrets.id_ed25519_scaleway_pub = {
    sopsFile = ../secrets/ssh.yaml;
    path = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway.pub";
  };
  launchd.agents.ssh-add-keychain = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "com.user.ssh-add-keychain";
      ProgramArguments = [
        "/usr/bin/ssh-add"
        "--apple-use-keychain"
        "${config.xdg.dataHome}/ssh/id_rsa"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/ssh-add-keychain.log";
      StandardErrorPath = "/tmp/ssh-add-keychain.log";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
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

      "scaleway_bastion" = {
        hostname = "51.15.221.197";
        port = 61000;
        user = "bastion";
        identityFile = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway";
      };

      "platform-*" = {
        user = "root";
        identityFile = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway";
        extraOptions = {
          ProxyJump = "scaleway_bastion";
        };
      };

      "*.mention.net" = {
        user = "mention";
        extraOptions = {
          ProxyJump = "ssh_bastion";
        };
      };

      "*" = {
        identityFile = "${config.xdg.dataHome}/ssh/id_rsa";
        userKnownHostsFile = "${config.xdg.dataHome}/ssh/known_hosts";
        extraOptions = {
          ForwardAgent = "no";
          ServerAliveInterval = "0";
          ServerAliveCountMax = "3";
          Compression = "no";
          AddKeysToAgent = "yes";
          HashKnownHosts = "no";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
          UseKeychain = if pkgs.stdenv.isDarwin then "yes" else "no";
        };
      };
    };
  };
}
