{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.gemini-cli;
  skillCommands = {
    check = "Fix lint, test, build, and formatting failures until the repository is green.";
    describe = "Review a jj changeset and apply an accurate emoji conventional commit description.";
    "fix-gh-issue" = "Investigate and fix a GitHub issue using gh and local validation.";
    next = "Execute a production-quality implementation workflow with research, planning, implementation, and validation.";
    prompt = "Generate a reusable implementation prompt for another coding agent.";
    validate = "Perform a direct post-implementation review for completeness, quality, and hidden risks.";
  };
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
      commands = lib.mapAttrs (name: description: {
        inherit description;
        prompt = builtins.readFile (./skills + "/${name}/SKILL.md");
      }) skillCommands;
    };

    home.file.".gemini/CONTEXT.md".source = ./CONTEXT.md;
  };
}
