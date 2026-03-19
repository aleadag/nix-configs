{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.gemini-cli;
  sharedPermissions = import ./permissions.nix { inherit lib; };
in
{
  options.home-manager.dev.coding-agents.gemini-cli = {
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
        # migrate to Policy Engine
        policyPaths = [ "~/.gemini/policies" ];
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

    home.file = {
      ".gemini/CONTEXT.md".source = ./CONTEXT.md;
      ".gemini/policies/shell-rules.toml".source = (pkgs.formats.toml { }).generate "gemini-shell-rules" {
        rule = sharedPermissions.geminiAllowedPolicyRules;
      };
    };
  };
}
