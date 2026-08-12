{ config, ... }:

{
  programs.scwx = {
    enable = true;
    settings = {
      ssh.key = "${config.xdg.dataHome}/ssh/id_ed25519_scaleway";
      naming.strip_prefixes = [ "platform-ingestor-" ];
      db.secret_project_id = "2b793d22-5853-4971-80f4-9f54ad77de44";
    };
  };
}
