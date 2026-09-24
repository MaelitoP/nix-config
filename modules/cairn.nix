{ config, ... }:

{
  programs.cairn = {
    enable = true;
    daemon.enable = true;
    settings = {
      repositories = [
        "mentionapp/mention"
        "agorapulse/platform-ingestor"
        "mentionapp/common-go"
        "mentionapp/ansible"
      ];
      checkout_roots = [ "${config.home.homeDirectory}/dev" ];
      github_login = "MaelitoP";
      shortcut_token_path = config.sops.secrets.shortcut_api_token.path;
      projects_root = "${config.home.homeDirectory}/dev/claude-projects";
      nix_config_path = "${config.home.homeDirectory}/dev/nix-config";
    };
  };
}
