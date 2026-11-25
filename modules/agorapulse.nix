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

  # The dev .p12 is encrypted with RC2/3DES, which OpenSSL 3 only reads through the legacy provider.
  opensslLegacyConf = pkgs.writeText "openssl-legacy.cnf" ''
    openssl_conf = openssl_init

    [openssl_init]
    providers = provider_sect

    [provider_sect]
    default = default_sect
    legacy = legacy_sect

    [default_sect]
    activate = 1

    [legacy_sect]
    activate = 1
  '';

  grafana = pkgs.writeShellApplication {
    name = "grafana";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
    ];
    text = ''
      GRAFANA_URL=https://grafana.mention.net:3000
      GRAPHITE_UID=000000001
      P12_PATH=${p12Path}
      P12_PASSWORD_FILE=${config.sops.secrets.p12_password.path}
      TOKEN_FILE=${config.sops.secrets.grafana_token.path}
      export OPENSSL_CONF=${opensslLegacyConf}
      export OPENSSL_MODULES=${pkgs.openssl.out}/lib/ossl-modules
    ''
    + builtins.readFile ../resources/grafana.sh;
  };

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
  imports = [
    ./cairn.nix
    ./scwx.nix
  ];

  sops.secrets = {
    nomad_token = {
      sopsFile = ../secrets/agorapulse.yaml;
      path = "${config.xdg.configHome}/nomad/token";
    };
    historical_netrc = {
      sopsFile = ../secrets/agorapulse.yaml;
      path = "${config.xdg.configHome}/historical/netrc.historical_ingestor";
    };
    grafana_token = {
      sopsFile = ../secrets/agorapulse.yaml;
      path = "${config.xdg.configHome}/grafana/token";
    };
    p12_password.sopsFile = ../secrets/agorapulse.yaml;
    client_key_dev_p12 = {
      sopsFile = ../secrets/client-key_dev.p12;
      format = "binary";
      path = p12Path;
    };
  };

  xdg.configFile."historical/ca.pem".source = ../resources/historical-ca.pem;

  home.packages = [ grafana ];

  programs.zsh.shellAliases = {
    cdi = "cd ~/dev/platform-ingestor";
    iup = "cdi; ./tools/devenv.sh up";
    istop = "cdi; ./tools/devenv.sh stop";
    irdbt = "cdi; ./tools/reset-db.sh test";
    irdtd = "cdi; ./tools/reset-db.sh dev";
    itest = "cdi; ./tools/run-tests.sh";

    cdm = "cd ~/dev/mention";
    mup = "cdm; ./tools/devenv.sh up";
    mstop = "cdm; ./tools/devenv.sh stop";
    mrdbt = "cdm; ./tools/reset-db.sh test";
    mrdtd = "cdm; ./tools/reset-db.sh dev";
    mtest = "cdm; ./tools/run-tests.sh";
    mphp = "docker exec -it php_cli";
    mysql56 = "mphp mysql -u mention -p -h mysql_5_6";
    mysql57 = "mphp mysql -u mention -p -h mysql_5_7";
  };

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
