{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.home.homeDirectory;
  environmentDir = "${home}/.agorapulse/environment";
  p12Path = "${config.xdg.dataHome}/certificat/client-key_dev_mael.lepetit.p12";

  decrypt =
    file: key:
    "SOPS_AGE_KEY_FILE=${config.sops.age.keyFile} ${pkgs.sops}/bin/sops decrypt --extract '[\"${key}\"]' ${file}";

  environment = {
    ".SCALEWAY_SSH_CONFIG" = ''SSH_KEY="${config.xdg.dataHome}/ssh/id_ed25519_scaleway"'';
    ORGANIZATION_UNIT = "tech/data";
    PLATFORM_PATH = "${home}/dev/platform";
    PULSE_SKIP_CLAUDE_COMMANDS = "true";
    PULSE_SKIP_MCP = "true";
    SHORTCUT_GROUP_ID = "6810ed64-0029-4375-a9f7-c94cb773ab97";
    SHORTCUT_MEMBER_ID = "6809421b-63f7-466c-bd6d-6314ae731397";
    SHORTCUT_MEMBER_NAME = "maelito";
    SHORTCUT_TRIBE = "platform";
  };

  secretEnvironment = {
    AGORAPULSE_API_KEY = decrypt ../secrets/agorapulse.yaml "agorapulse_api_key";
    CLUBHOUSE_TOKEN = decrypt ../secrets/common.yaml "shortcut_api_token";
    DD_API_KEY = decrypt ../secrets/agorapulse.yaml "dd_api_key";
    DD_APP_KEY = decrypt ../secrets/agorapulse.yaml "dd_app_key";
    FIGMA_API_KEY = decrypt ../secrets/agorapulse.yaml "figma_api_key";
    SENTRY_AGORAPULSE_BOT_TOKEN = decrypt ../secrets/agorapulse.yaml "sentry_agorapulse_bot_token";
    SHORTCUT_TOKEN = decrypt ../secrets/common.yaml "shortcut_api_token";
    SLITE_API_KEY = decrypt ../secrets/common.yaml "slite_api_key";
    SONARCLOUD_API_KEY = decrypt ../secrets/agorapulse.yaml "sonarcloud_api_key";
  };
in
{
  sops.secrets = {
    nomad_token = {
      sopsFile = ../secrets/agorapulse.yaml;
      path = "${config.xdg.configHome}/nomad/token";
    };
    historical_netrc = {
      sopsFile = ../secrets/agorapulse.yaml;
      path = "${config.xdg.configHome}/historical/netrc.historical_ingestor";
    };
    p12_password.sopsFile = ../secrets/agorapulse.yaml;
    client_key_dev_p12 = {
      sopsFile = ../secrets/client-key_dev.p12;
      format = "binary";
      path = p12Path;
    };
  };

  xdg.configFile."historical/ca.pem".source = ../resources/historical-ca.pem;

  programs.zsh.initContent = ''
    export P12_CERTIFICATE_PATH="${p12Path}"
    [ -r "${config.sops.secrets.p12_password.path}" ] && \
      export P12_CERTIFICATE_PASSWORD="$(<"${config.sops.secrets.p12_password.path}")"
  '';

  # pulse writes to these files, so they stay plain files instead of read-only sops symlinks.
  # They are decrypted here rather than read from the sops-nix agent, which reloads asynchronously on macOS.
  home.activation.agorapulseEnvironment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      umask 077
      mkdir -p ${environmentDir} ${home}/.aws
      ${lib.concatStrings (
        lib.mapAttrsToList (name: value: ''
          printf '%s\n' ${lib.escapeShellArg value} > ${environmentDir}/${name}
        '') environment
      )}
      ${lib.concatStrings (
        lib.mapAttrsToList (name: command: ''
          value=$(${command})
          printf '%s\n' "$value" > ${environmentDir}/${name}
        '') secretEnvironment
      )}
      value=$(${decrypt ../secrets/agorapulse.yaml "aws_credentials"})
      printf '%s\n' "$value" > ${home}/.aws/credentials
    )
  '';
}
