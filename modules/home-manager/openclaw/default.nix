{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.openclaw;
  secretOpts = lib.optionalAttrs (cfg.sopsFile != null) {
    inherit (cfg) sopsFile;
  };
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
  };

  # TODO(nix-openclaw): Remove once feishu is added to upstream generated schema.
  # See: https://github.com/openclaw/nix-openclaw
  options.programs.openclaw.instances = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.config = lib.mkOption {
          type = lib.types.submodule {
            options.channels = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.submodule {
                  options.feishu = lib.mkOption {
                    type = lib.types.nullOr lib.types.attrs;
                    default = null;
                  };
                }
              );
            };
          };
        };
      }
    );
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "openclaw/token" = secretOpts;
        "openclaw/feishu/main/app_id" = secretOpts;
        "openclaw/feishu/main/app_secret" = secretOpts;
        "openclaw/feishu/aurora/app_id" = secretOpts;
        "openclaw/feishu/aurora/app_secret" = secretOpts;
        "openclaw/feishu/ticos/app_id" = secretOpts;
        "openclaw/feishu/ticos/app_secret" = secretOpts;
        "openclaw/feishu/zsflow/app_id" = secretOpts;
        "openclaw/feishu/zsflow/app_secret" = secretOpts;
        "openclaw/zai_api_key" = secretOpts;
      };
      templates.openclaw-env = {
        content = ''
          OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/token"}
          FEISHU_MAIN_APP_ID=${config.sops.placeholder."openclaw/feishu/main/app_id"}
          FEISHU_MAIN_APP_SECRET=${config.sops.placeholder."openclaw/feishu/main/app_secret"}
          FEISHU_AURORA_APP_ID=${config.sops.placeholder."openclaw/feishu/aurora/app_id"}
          FEISHU_AURORA_APP_SECRET=${config.sops.placeholder."openclaw/feishu/aurora/app_secret"}
          FEISHU_TICOS_APP_ID=${config.sops.placeholder."openclaw/feishu/ticos/app_id"}
          FEISHU_TICOS_APP_SECRET=${config.sops.placeholder."openclaw/feishu/ticos/app_secret"}
          FEISHU_ZSFLOW_APP_ID=${config.sops.placeholder."openclaw/feishu/zsflow/app_id"}
          FEISHU_ZSFLOW_APP_SECRET=${config.sops.placeholder."openclaw/feishu/zsflow/app_secret"}
          ZAI_API_KEY=${config.sops.placeholder."openclaw/zai_api_key"}
        '';
        path = "${config.home.homeDirectory}/.openclaw/.env";
      };
    };

    home.file.".openclaw/openclaw.json".force = true;

    programs.openclaw = {
      package = pkgs.llm-agents.openclaw;
      documents = ./docs;

      instances.default = {
        inherit (cfg) gatewayPort;
        package = pkgs.llm-agents.openclaw;

        enable = true;
        config = {
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
              {
                id = "main";
                workspace = "~/.openclaw/workspace-main";
              }
              {
                id = "aurora";
                workspace = "~/.openclaw/workspace-aurora";
              }
              {
                id = "ticos";
                workspace = "~/.openclaw/workspace-ticos";
              }
              {
                id = "zsflow";
                workspace = "~/.openclaw/workspace-zsflow";
              }
            ];
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
            accounts = {
              main = {
                appId = "\${FEISHU_MAIN_APP_ID}";
                appSecret = "\${FEISHU_MAIN_APP_SECRET}";
              };
              aurora = {
                appId = "\${FEISHU_AURORA_APP_ID}";
                appSecret = "\${FEISHU_AURORA_APP_SECRET}";
              };
              ticos = {
                appId = "\${FEISHU_TICOS_APP_ID}";
                appSecret = "\${FEISHU_TICOS_APP_SECRET}";
              };
              zsflow = {
                appId = "\${FEISHU_ZSFLOW_APP_ID}";
                appSecret = "\${FEISHU_ZSFLOW_APP_SECRET}";
              };
            };
          };

          bindings = [
            {
              agentId = "main";
              match = {
                channel = "feishu";
                accountId = "main";
              };
            }
            {
              agentId = "aurora";
              match = {
                channel = "feishu";
                accountId = "aurora";
              };
            }
            {
              agentId = "ticos";
              match = {
                channel = "feishu";
                accountId = "ticos";
              };
            }
            {
              agentId = "zsflow";
              match = {
                channel = "feishu";
                accountId = "zsflow";
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
        };

        plugins = [
        ];
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
