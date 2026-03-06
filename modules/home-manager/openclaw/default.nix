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
    programs.openclaw = {
      enable = true;
      documents = ./docs;

      config = {
        gateway = {
          mode = "local";
          auth = {
            # You should change this or use a file
            token = "change-me-locally-securely";
          };
        };

        # Add Anthropic key if needed for tools/gateway
        # providers.anthropic.apiKeyFile = "${config.home.homeDirectory}/.secrets/anthropic-key";
      };

      instances.default = {
        enable = true;
        plugins = [
          # Add plugins here
        ];
      };
    };
  };
}
