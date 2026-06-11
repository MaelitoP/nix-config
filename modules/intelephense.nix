{ config, ... }:

{
  sops.secrets.intelephense_licence = {
    sopsFile = ../secrets/common.yaml;
    path = "${config.home.homeDirectory}/intelephense/licence.txt";
  };
}
