{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.gemini-cli;
in
{
  options.home-manager.dev.gemini-cli = {
    enable = lib.mkEnableOption "Gemini-cli config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gemini-cli = {
      enable = true;
      package = pkgs.llm-agents.gemini-cli;
      settings = {
        general = {
          preferredEditor = "nvim";
          previewFeatures = true;
        };
        ide.enabled = true;
        privacy.usageStatisticsEnabled = false;
        # if we don't have this, it will ask for login for every new session
        security.auth.selectedType = "oauth-personal";
        context.fileName = [ "CONTEXT.md" ];
        tools = {
          autoAccept = false;
          enableHooks = true;
        };
        hooks = {
          AfterTool = [
            {
              matcher = "write_file|replace";
              hooks = [
                {
                  name = "jj-auto-new";
                  type = "command";
                  command = "jj new";
                  description = "Auto-create new change after file modification";
                }
              ];
            }
          ];
        };
      };
    };

    home.file.".gemini/CONTEXT.md".source = ./CONTEXT.md;
  };
}
