{
  config,
  lib,
  pkgs,
  ...
}:

let
  miseConfig = pkgs.writeText "mise-config.toml" ''
    [settings]
    experimental = true

    [tools]
    java = "zulu-25"
    node = "lts"
    terraform = "latest"
  '';
in
{
  # pulse rewrites this file with `mise use -g`, so it stays a plain file instead of a read-only symlink.
  home.activation.miseConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install -D -m 0644 ${miseConfig} ${config.xdg.configHome}/mise/config.toml
  '';
}
