{ config, ... }:

{
  programs.scwx = {
    enable = true;
    settings = {
      ssh.key = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway";
      ssh.domains = {
        prod = "platform-ingestor-prod-network.internal";
        beta = "platform-ingestor-beta-network.internal";
      };
      naming.strip_prefixes = [ "platform-ingestor-" ];
      db.secret_project_id = "2b793d22-5853-4971-80f4-9f54ad77de44";
    };
  };
}
