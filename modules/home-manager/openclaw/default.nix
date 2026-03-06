{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.openclaw;
in
{
  options.home-manager.openclaw.enable = lib.mkEnableOption "openclaw";

  config = lib.mkIf cfg.enable {
    sops.secrets.openclaw_token = { };

    home.file.".openclaw/openclaw.json".force = true;

    programs.openclaw = {
      documents = ./docs;

      instances.default = {
        enable = true;
        gatewayPort = 19789;
        config = {
          gateway = {
            mode = "local";
            port = 19789;
            auth = {
              # You should change this or use a file
              token = config.sops.placeholder.openclaw_token;
            };
          };

          # Add Anthropic key if needed for tools/gateway
          # providers.anthropic.apiKeyFile = "${config.home.homeDirectory}/.secrets/anthropic-key";
        };

        plugins = [
          # Add plugins here
        ];
      };
    };
  };
}
