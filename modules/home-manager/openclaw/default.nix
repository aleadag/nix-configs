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
    sops.secrets = {
      "openclaw/token" = { };
      "openclaw/feishu/app_id" = { };
      "openclaw/feishu/app_secret" = { };
    };

    home.file.".openclaw/openclaw.json".force = true;

    programs.openclaw = {
      package =
        let
          origPackage = config.programs.openclaw.package;
        in
        pkgs.symlinkJoin {
          name = "openclaw-wrapped";
          paths = [ origPackage ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/openclaw \
              --run 'export OPENCLAW_GATEWAY_TOKEN="$(cat ${config.sops.secrets."openclaw/token".path})"' \
              --run 'export FEISHU_APP_ID="$(cat ${config.sops.secrets."openclaw/feishu/app_id".path})"' \
              --run 'export FEISHU_APP_SECRET="$(cat ${config.sops.secrets."openclaw/feishu/app_secret".path})"'
          '';
        };

      documents = ./docs;

      instances.default = {
        enable = true;
        gatewayPort = 19789;
        config = {
          gateway = {
            mode = "local";
            port = 19789;
            auth = {
              mode = "token";
            };
          };

          channels.feishu = {
            enabled = true;
            dmPolicy = "open";
            allowFrom = [ "*" ];
          };

          plugins.entries.feishu.enabled = true;
        };

        plugins = [
        ];
      };
    };
  };
}
