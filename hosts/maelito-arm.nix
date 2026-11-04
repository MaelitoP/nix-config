{ ... }:

{
  imports = [
    ./default.nix
    ./wireguard.nix
  ];

  host = {
    username = "mael.lepetit";
    realname = "mael.lepetit";
    home = "/Users/mael.lepetit";
    platform = "aarch64-darwin";
    extraCasks = [
      "chatgpt"
      "codex"
      "codex-app"
      "whatsapp"
    ];
    extraBrews = [
      "bash"
      "debianutils"
      "ghz"
      "jq"
      "mise"
      "mysql-client"
      "openssl@3"
      "qemu"
      "riscv64-elf-gdb"
      "scw"
    ];
    extraHosts = ''
      127.0.0.1 ingestor.dev.agorapulse.network api.ingestor.dev.agorapulse.network doc.ingestor.dev.agorapulse.network
      127.0.0.1 d.mention.net en.d.mention.net fr.d.mention.net de.d.mention.net es.d.mention.net web.d.mention.net portainer.d.mention.net
      127.0.0.1 www.d.mention.net m.d.mention.net m.en.d.mention.net m.fr.d.mention.net m.de.d.mention.net favatar.d.mention.net rss.d.mention.net favorites.d.mention.net dev.d.mention.net api.d.mention.net admin.d.mention.net mail-redir.d.mention.net
      127.0.0.1 d.mention.com en.d.mention.com fr.d.mention.com de.d.mention.com es.d.mention.com
      127.0.0.1 web.d.mention.com www.d.mention.com m.d.mention.com m.en.d.mention.com m.fr.d.mention.com m.de.d.mention.com favatar.d.mention.com rss.d.mention.com favorites.d.mention.com dev.d.mention.com api.d.mention.com admin.d.mention.com mail-redir.d.mention.com
    '';
  };
}
