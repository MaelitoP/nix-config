{
  config,
  lib,
  pkgs,
  ...
}:

let
  githubTokenPath = "${config.xdg.configHome}/secrets/github_token";
  nixTokenFile = "${config.xdg.configHome}/nix/access-tokens.conf";
in
{
  nix.settings = {
    use-xdg-base-directories = true;
    experimental-features = "nix-command flakes";
  };

  nix.extraOptions = ''
    !include ${nixTokenFile}
  '';

  sops.secrets.github_token = {
    sopsFile = ../secrets/common.yaml;
    path = githubTokenPath;
  };

  home.activation.createNixAccessToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install -d -m 0700 ${config.xdg.configHome}/nix
    echo "access-tokens = github.com=$(<${githubTokenPath})" > ${nixTokenFile}
    chmod 0600 ${nixTokenFile}
  '';
}
