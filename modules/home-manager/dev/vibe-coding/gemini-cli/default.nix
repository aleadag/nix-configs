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
      };
      commands = {
        describe = {
          description = "Create well-formatted change descriptions with conventional commit messages and emoji, then apply them";
          prompt = builtins.readFile ../commands/describe.md;
          "allowed-tools" =
            "Bash(jj status:*), Bash(jj diff:*), Bash(jj describe:*), Bash(jj log:*), Bash(jj show:*)";
        };
      };
    };
  };
}
