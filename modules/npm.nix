{
  config,
  lib,
  ...
}:

let
  npmTokenPath = "${config.xdg.configHome}/secrets/npm_access_token";
  npmrcFile = "${config.xdg.configHome}/npm/npmrc";
in
{
  sops.secrets.npm_access_token = {
    sopsFile = ../secrets/common.yaml;
    path = npmTokenPath;
  };

  home.activation.createNpmrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install -d -m 0700 ${config.xdg.configHome}/npm
    cat > ${npmrcFile} <<EOF
    prefix=${config.home.homeDirectory}/.npm-packages
    //registry.npmjs.org/:_authToken=$(<${npmTokenPath})
    EOF
    chmod 0600 ${npmrcFile}
  '';
}
