{ ... }:

{
  imports = [ ./default.nix ];

  host = {
    username = "mael.lepetit";
    realname = "mael.lepetit";
    home = "/Users/mael.lepetit";
    platform = "aarch64-darwin";
    extraCasks = [ ];
    extraBrews = [
      "bash"
      "debianutils"
      "jq"
      "mise"
      "mysql-client"
      "openssl@3"
      "scw"
    ];
  };
}
