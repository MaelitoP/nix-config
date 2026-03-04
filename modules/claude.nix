{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.programs.claude;

  mkMcpServerWrapper =
    name: server:
    let
      envVars = lib.concatStringsSep "\n" (
        (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") server.env)
        ++ (lib.mapAttrsToList (
          k: secretPath: "export ${k}=\"$(cat ${config.sops.secrets."${secretPath}".path})\""
        ) server.envSecrets)
      );

      fullCommand = "${server.command} ${lib.concatStringsSep " " server.args}";
    in
    {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        ${envVars}
        exec ${fullCommand}
      '';
    };

  mcpServersConfig = lib.mapAttrs (name: server: {
    type = server.type;
    command = "${config.home.homeDirectory}/.claude/mcp-servers/${name}-wrapper";
    args = [ ];
    env = { };
  }) cfg.mcpServers;

  settingsFile = pkgs.writeText "claude-settings.json" (builtins.toJSON {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    enabledPlugins = cfg.settings.enabledPlugins;
    alwaysThinkingEnabled = cfg.settings.alwaysThinkingEnabled;
    attribution = cfg.settings.attribution;
  });

  claudeMdFile = ../resources/claude/CLAUDE.md;
  skillsDir = ../resources/claude/skills;

in
{
  options.programs.claude = {
    enable = mkEnableOption "Claude Code";

    settings = {
      alwaysThinkingEnabled = mkOption {
        type = types.bool;
        default = true;
        description = "Enable always-thinking mode";
      };

      enabledPlugins = mkOption {
        type = types.attrsOf types.bool;
        default = { };
        description = "Enabled LSP plugins";
        example = {
          "pyright-lsp@claude-plugins-official" = true;
          "php-lsp@claude-plugins-official" = true;
        };
      };

      attribution = mkOption {
        type = types.submodule {
          options = {
            commit = mkOption {
              type = types.str;
              default = "";
              description = "Attribution text for commits (empty string to disable)";
            };

            pr = mkOption {
              type = types.str;
              default = "";
              description = "Attribution text for PRs (empty string to disable)";
            };
          };
        };
        default = {
          commit = "";
          pr = "";
        };
        description = "Attribution settings for commits and pull requests";
      };
    };

    mcpServers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            type = mkOption {
              type = types.enum [
                "stdio"
                "sse"
              ];
              default = "stdio";
              description = "MCP server type";
            };

            command = mkOption {
              type = types.str;
              description = "Command to run the MCP server";
            };

            args = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Arguments to pass to the command";
            };

            env = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Environment variables (plain text values)";
            };

            envSecrets = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Environment variables from sops secrets (map of env var name to secret path)";
              example = {
                GITHUB_TOKEN = "claude_code/github_token";
              };
            };
          };
        }
      );
      default = { };
      description = "MCP servers configuration";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.file = lib.mkMerge [
        {
          ".claude/mcp-servers-nix.json" = {
            text = builtins.toJSON mcpServersConfig;
          };
        }

        (lib.mapAttrs' (
          name: server:
          lib.nameValuePair ".claude/mcp-servers/${name}-wrapper" (mkMcpServerWrapper name server)
        ) cfg.mcpServers)
      ];

      sops.secrets = lib.mkMerge (
        lib.flatten (
          lib.mapAttrsToList (
            serverName: server:
            lib.mapAttrsToList (envVar: secretPath: {
              "${secretPath}" = {
                sopsFile = ../secrets/common.yaml;
              };
            }) server.envSecrets
          ) cfg.mcpServers
        )
      );

      home.activation.updateClaudeMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -f ~/.claude.json ]; then
          $DRY_RUN_CMD ${pkgs.jq}/bin/jq -s '.[0] * {mcpServers: (((.[0].mcpServers // {}) | del(.github, .slite, .shortcut)) * .[1])}' \
            ~/.claude.json \
            ~/.claude/mcp-servers-nix.json \
            > ~/.claude.json.tmp && \
            $DRY_RUN_CMD mv ~/.claude.json.tmp ~/.claude.json
        else
          echo "Warning: ~/.claude.json does not exist, skipping MCP config merge"
        fi
      '';

      home.activation.writeClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD install -Dm644 ${settingsFile} ${config.home.homeDirectory}/.claude/settings.json
      '';

      home.activation.writeClaudeMemory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD install -Dm644 ${claudeMdFile} ${config.home.homeDirectory}/.claude/CLAUDE.md
      '';

      home.activation.writeClaudeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD rm -rf ${config.home.homeDirectory}/.claude/skills
        $DRY_RUN_CMD cp -r ${skillsDir} ${config.home.homeDirectory}/.claude/skills
        $DRY_RUN_CMD chmod -R u+w ${config.home.homeDirectory}/.claude/skills
      '';
    })

    {
      programs.claude = {
        enable = true;

        settings = {
          alwaysThinkingEnabled = true;

          enabledPlugins = {
            "pyright-lsp@claude-plugins-official" = true;
            "php-lsp@claude-plugins-official" = true;
            "clangd-lsp@claude-plugins-official" = true;
            "lua-lsp@claude-plugins-official" = true;
            "slack@claude-plugins-official" = true;
          };

          attribution = {
            commit = "";
            pr = "";
          };
        };

        mcpServers = {
          github = {
            type = "stdio";
            command = "docker";
            args = [
              "run"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "ghcr.io/github/github-mcp-server"
            ];
            envSecrets = {
              GITHUB_PERSONAL_ACCESS_TOKEN = "github_token";
            };
          };

          slite = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "slite-mcp-server"
            ];
            envSecrets = {
              SLITE_API_KEY = "slite_api_key";
            };
          };

          shortcut = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@shortcut/mcp"
            ];
            envSecrets = {
              SHORTCUT_API_TOKEN = "shortcut_api_token";
            };
          };
        };
      };
    }
  ];
}
