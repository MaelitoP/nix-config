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
      "mysql-client"
    ];
  };
}
