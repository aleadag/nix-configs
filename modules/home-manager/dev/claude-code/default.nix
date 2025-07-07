{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.claude-code;
in
{
  options.home-manager.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI tool" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Claude Code package
    home.packages = with pkgs; [
      claude-code
    ];

    # Claude Code settings from sops
    sops = {
      secrets = {
        anthropic_base_url = { };
        anthropic_auth_token = { };
      };
      templates."claude-settings.json" = {
        content = builtins.toJSON {
          env = {
            ANTHROPIC_BASE_URL = config.sops.placeholder.anthropic_base_url;
            ANTHROPIC_AUTH_TOKEN = config.sops.placeholder.anthropic_auth_token;
          };
          hooks = {
            PostToolUse = [
              {
                matcher = "Write|Edit|MultiEdit";
                hooks = [
                  {
                    type = "command";
                    command = "~/.claude/hooks/smart-lint.sh";
                  }
                  {
                    type = "command";
                    command = "~/.claude/hooks/smart-test.sh";
                  }
                ];
              }
            ];
            Stop = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "~/.claude/hooks/ntfy-notifier.sh notification";
                  }
                ];
              }
            ];
          };
        };
        path = "${config.home.homeDirectory}/.claude/settings.json";
      };
    };

    # Create and manage ~/.claude directory
    home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;

    # Copy hook scripts with executable permissions
    home.file.".claude/hooks/common-helpers.sh" = {
      source = ./hooks/common-helpers.sh;
      executable = true;
    };

    home.file.".claude/hooks/smart-lint.sh" = {
      source = ./hooks/smart-lint.sh;
      executable = true;
    };

    home.file.".claude/hooks/smart-test.sh" = {
      source = ./hooks/smart-test.sh;
      executable = true;
    };

    home.file.".claude/hooks/ntfy-notifier.sh" = {
      source = ./hooks/ntfy-notifier.sh;
      executable = true;
    };

    # Copy documentation and examples (not executable)
    home.file.".claude/hooks/README.md".source = ./hooks/README.md;
    home.file.".claude/hooks/example-claude-hooks-config.sh".source =
      ./hooks/example-claude-hooks-config.sh;
    home.file.".claude/hooks/example-claude-hooks-ignore".source = ./hooks/example-claude-hooks-ignore;

    # Copy command files
    home.file.".claude/commands/check.md".source = ./commands/check.md;
    home.file.".claude/commands/next.md".source = ./commands/next.md;
    home.file.".claude/commands/prompt.md".source = ./commands/prompt.md;

    # Create necessary directories
    home.file.".claude/.keep".text = "";
    home.file.".claude/projects/.keep".text = "";
    home.file.".claude/todos/.keep".text = "";
    home.file.".claude/statsig/.keep".text = "";
    home.file.".claude/commands/.keep".text = "";
  };
}
