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
        general.previewFeatures = true;
        # if we don't have this, it will ask for login for every new session
        security.auth.selectedType = "oauth-personal";
        context.fileName = [ "CONTEXT.md" ];
      };
      commands = {
        check = {
          description = "Verify code quality, run tests, and ensure production readiness";
          prompt = builtins.readFile ./commands/check.md;
          "allowed-tools" = "all";
        };
        describe = {
          description = "Create well-formatted change descriptions with conventional commit messages and emoji, then apply them";
          prompt = builtins.readFile ./commands/describe.md;
          "allowed-tools" =
            "Bash(jj status:*), Bash(jj diff:*), Bash(jj describe:*), Bash(jj log:*), Bash(jj show:*)";
        };
        "fix-gh-issue" = {
          description = "Analyze and fix a GitHub issue";
          prompt = builtins.readFile ./commands/fix-gh-issue.md;
          "allowed-tools" = "all";
        };
        next = {
          description = "Execute production-quality implementation with strict standards";
          prompt = builtins.readFile ./commands/next.md;
          "allowed-tools" = "all";
        };
        prompt = {
          description = "Synthesize a complete prompt by combining next.md with your arguments";
          prompt = builtins.readFile ./commands/prompt.md;
          "allowed-tools" = "all";
        };
        validate = {
          description = "Deep validation of completed implementation";
          prompt = builtins.readFile ./commands/validate.md;
          "allowed-tools" = "all";
        };
      };
    };

    home.file.".gemini/CONTEXT.md".source = ./CONTEXT.md;
  };
}