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
  agentId = "main";

  # Helper to convert feishu account id to env var name part (e.g. "main" -> "MAIN")
  toEnv = id: lib.toUpper (lib.replaceStrings [ "-" "." ] [ "_" "_" ] id);
  feishuAccount = "main";
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

    workspace = lib.mkOption {
      type = lib.types.str;
      default = "~/.openclaw/workspace-${agentId}";
      description = "The workspace directory for the OpenClaw agent.";
    };

    extraAgentConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration merged into the OpenClaw agent config.";
    };

    extraInstanceConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra configuration merged into the OpenClaw instance config.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = lib.mkMerge [
        { "openclaw/token" = secretOpts; }
        { "openclaw/zai_api_key" = secretOpts; }
        { "openclaw/feishu/${feishuAccount}/app_id" = secretOpts; }
        { "openclaw/feishu/${feishuAccount}/app_secret" = secretOpts; }
      ];

      templates.openclaw-env = {
        content = ''
          OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/token"}
          ZAI_API_KEY=${config.sops.placeholder."openclaw/zai_api_key"}
          FEISHU_${toEnv feishuAccount}_APP_ID=${
            config.sops.placeholder."openclaw/feishu/${feishuAccount}/app_id"
          }
          FEISHU_${toEnv feishuAccount}_APP_SECRET=${
            config.sops.placeholder."openclaw/feishu/${feishuAccount}/app_secret"
          }
        '';
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

            list = [
              (lib.recursiveUpdate {
                id = agentId;
                inherit (cfg) workspace;
              } cfg.extraAgentConfig)
            ];
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
            accounts.${feishuAccount} = {
              appId = "\${FEISHU_${toEnv feishuAccount}_APP_ID}";
              appSecret = "\${FEISHU_${toEnv feishuAccount}_APP_SECRET}";
            };
          };

          bindings = [
            {
              inherit agentId;
              match = {
                channel = "feishu";
                accountId = feishuAccount;
              };
            }
          ];

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
