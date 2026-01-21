{
  config,
  lib,
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
      commands = {
        check = {
          description = "Verify code quality, run tests, and ensure production readiness";
          prompt = builtins.readFile ./commands/check.md;
        };
        describe = {
          description = "Create well-formatted change descriptions with conventional commit messages and emoji, then apply them";
          prompt = builtins.readFile ./commands/describe.md;
        };
        "fix-gh-issue" = {
          description = "Analyze and fix a GitHub issue";
          prompt = builtins.readFile ./commands/fix-gh-issue.md;
        };
        next = {
          description = "Execute production-quality implementation with strict standards";
          prompt = builtins.readFile ./commands/next.md;
        };
        prompt = {
          description = "Synthesize a complete prompt by combining next.md with your arguments";
          prompt = builtins.readFile ./commands/prompt.md;
        };
        validate = {
          description = "Deep validation of completed implementation";
          prompt = builtins.readFile ./commands/validate.md;
        };
      };
    };

    home.file.".gemini/CONTEXT.md".source = ./CONTEXT.md;
  };
}
