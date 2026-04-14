{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.openclaw;
  flakeInputSource =
    input:
    let
      inherit (input.sourceInfo)
        owner
        repo
        rev
        narHash
        ;
    in
    "github:${owner}/${repo}/${rev}?narHash=${narHash}";
  lifewikiSkillsPluginSource = flakeInputSource flake.inputs.lifewiki-skills;
  secretOpts = lib.optionalAttrs (cfg.sopsFile != null) {
    inherit (cfg) sopsFile;
  };

  # Helper to convert feishu account id to env var name part (e.g. "main" -> "MAIN")
  toEnv = id: lib.toUpper (lib.replaceStrings [ "-" "." ] [ "_" "_" ] id);
in
{
  options.home-manager.openclaw = {
    enable = lib.mkEnableOption "openclaw";

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional SOPS file for OpenClaw secrets. When null, uses the global
        `sops.defaultSopsFile`.
      '';
    };

    gatewayPort = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "The port the OpenClaw gateway will listen on.";
    };

    agents = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              id = lib.mkOption {
                type = lib.types.str;
                description = "The unique ID of the agent.";
              };
              workspace = lib.mkOption {
                type = lib.types.str;
                default = "~/.openclaw/workspace-${config.id}";
                description = "The workspace directory for the agent.";
              };
              feishuAccount = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "If set, automatically creates a feishu binding for this agent.";
              };
              extraConfig = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = "Extra configuration merged into the agent entry in agents.list.";
              };
            };
          }
        )
      );
      default = [ ];
      description = "List of agents to configure.";
    };

    feishuAccounts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of feishu account IDs to configure secrets and channels for.";
    };

    extraInstanceConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration merged into programs.openclaw.instances.default.config.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = lib.mkMerge (
        [
          { "openclaw/token" = secretOpts; }
          { "openclaw/zai_api_key" = secretOpts; }
        ]
        ++ (map (id: {
          "openclaw/feishu/${id}/app_id" = secretOpts;
          "openclaw/feishu/${id}/app_secret" = secretOpts;
        }) cfg.feishuAccounts)
      );

      templates.openclaw-env = {
        content = ''
          OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/token"}
          ZAI_API_KEY=${config.sops.placeholder."openclaw/zai_api_key"}
        ''
        + (lib.concatMapStringsSep "\n" (id: ''
          FEISHU_${toEnv id}_APP_ID=${config.sops.placeholder."openclaw/feishu/${id}/app_id"}
          FEISHU_${toEnv id}_APP_SECRET=${config.sops.placeholder."openclaw/feishu/${id}/app_secret"}
        '') cfg.feishuAccounts);
        path = "${config.home.homeDirectory}/.openclaw/.env";
      };
    };

    home.file.".openclaw/openclaw.json".force = true;

    programs.openclaw = {
      package = pkgs.llm-agents.openclaw;
      documents = ./docs;
      customPlugins = [
        { source = lifewikiSkillsPluginSource; }
      ];

      instances.default = {
        inherit (cfg) gatewayPort;
        package = pkgs.llm-agents.openclaw;

        enable = true;
        config = lib.recursiveUpdate {
          agents = {
            defaults = {
              model = {
                primary = "zai/glm-5";
                fallbacks = [
                  "zai/glm-4.7"
                  "zai/glm-4.6"
                  "zai/glm-4.5-air"
                ];
              };
            };

            list = map (a: lib.recursiveUpdate { inherit (a) id workspace; } a.extraConfig) cfg.agents;
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
            accounts = lib.genAttrs cfg.feishuAccounts (id: {
              appId = "\${FEISHU_${toEnv id}_APP_ID}";
              appSecret = "\${FEISHU_${toEnv id}_APP_SECRET}";
            });
          };

          bindings = lib.flatten (
            map (
              a:
              lib.optional (a.feishuAccount != null) {
                agentId = a.id;
                match = {
                  channel = "feishu";
                  accountId = a.feishuAccount;
                };
              }
            ) cfg.agents
          );

          gateway = {
            mode = "local";
            port = cfg.gatewayPort;
            auth = {
              mode = "token";
              token = "\${OPENCLAW_GATEWAY_TOKEN}";
            };
          };

          session.dmScope = "per-channel-peer";

          plugins.entries.feishu.enabled = true;
        } cfg.extraInstanceConfig;

        plugins = [ ];
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "openclaw-local" ''
        set -euo pipefail

        export OPENCLAW_GATEWAY_TOKEN="$(cat "${config.sops.secrets."openclaw/token".path}")"

        exec ${pkgs.llm-agents.openclaw}/bin/openclaw "$@"
      '')
    ];
  };
}
