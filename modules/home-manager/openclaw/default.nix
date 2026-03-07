{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.openclaw;
in
{
  options.home-manager.openclaw.enable = lib.mkEnableOption "openclaw";

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
        "openclaw/token" = { };
        "openclaw/feishu/app_id" = { };
        "openclaw/feishu/app_secret" = { };
        "openclaw/zai_api_key" = { };
      };
      templates.openclaw-env = {
        content = ''
          OPENCLAW_GATEWAY_TOKEN=${config.sops.placeholder."openclaw/token"}
          FEISHU_APP_ID=${config.sops.placeholder."openclaw/feishu/app_id"}
          FEISHU_APP_SECRET=${config.sops.placeholder."openclaw/feishu/app_secret"}
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
        enable = true;
        gatewayPort = 19789;
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
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
            accounts.default = {
              appId = "\${FEISHU_APP_ID}";
              appSecret = "\${FEISHU_APP_SECRET}";
            };
          };

          gateway = {
            mode = "local";
            port = 19789;
            auth = {
              mode = "token";
              token = "\${OPENCLAW_GATEWAY_TOKEN}";
            };
          };

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
