{
  config,
  lib,
  pkgs,
  ...
}:

let
  scwConfig = "${config.xdg.configHome}/scw/config.yaml";
in
{
  # scw rejects a symlinked config as "too permissive", so it gets a plain 0600 file.
  home.activation.scwConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      umask 077
      mkdir -p "$(dirname ${scwConfig})"
      value=$(SOPS_AGE_KEY_FILE=${config.sops.age.keyFile} ${pkgs.sops}/bin/sops decrypt --extract '["scw_config"]' ${../secrets/common.yaml})
      rm -f ${scwConfig}
      printf '%s\n' "$value" > ${scwConfig}
    )
  '';
}
