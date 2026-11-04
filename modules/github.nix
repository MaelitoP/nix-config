{
  config,
  ...
}:

let
  githubTokenPath = "${config.xdg.configHome}/secrets/github_token";
in
{
  sops.secrets.github_token = {
    sopsFile = ../secrets/common.yaml;
    path = githubTokenPath;
  };

  sops.secrets.netrc = {
    sopsFile = ../secrets/common.yaml;
    path = "${config.home.homeDirectory}/.netrc";
  };
}
