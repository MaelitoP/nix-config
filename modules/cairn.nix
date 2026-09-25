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
      review.repositories."agorapulse/platform-ingestor" = {
        worktree_root = "${config.home.homeDirectory}/dev/platform-ingestor/.claude/worktrees";
        setup = [
          "/usr/local/bin/docker"
          "exec"
          "-u"
          "mention"
          "-w"
          "{worktree}"
          "ingestor-php_cli-1"
          "composer"
          "install"
          "--no-interaction"
          "--no-progress"
        ];
        instructions = ''
          Run the tests through `/usr/local/bin/docker exec -u mention -w {worktree} ingestor-php_cli-1 .composer/bin/phpunit ...`.
          The test database and Kafka are shared with the engineer's own test runs.
        '';
      };
    };
  };
}
