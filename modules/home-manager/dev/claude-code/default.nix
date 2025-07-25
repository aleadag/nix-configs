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
    # Install Claude Code package and ccusage
    home.packages = with pkgs; [
      claude-code
      just
    ];

    # Create and manage ~/.claude directory
    home.file =
      let
        # Dynamically read command files
        commandFiles = builtins.readDir ./commands;
        commandEntries = lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".md" name
        ) commandFiles;
        commandFileAttrs = lib.mapAttrs' (
          name: _: lib.nameValuePair ".claude/commands/${name}" { source = ./commands/${name}; }
        ) commandEntries;
      in
      commandFileAttrs
      // {
        # Claude Code settings from sops
        ".claude/settings.json".text = builtins.toJSON {
          env = {
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
            TZ = "America/Los_Angeles";
          }
          // lib.optionalAttrs config.home-manager.mihomo.enable (
            let
              # Claude Code does not support SOCKS proxies.
              proxy = "http://127.0.0.1:7890";
            in
            {
              HTTP_PROXY = proxy;
              HTTPS_PROXY = proxy;
            }
          );
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
                hooks = lib.optionals config.home-manager.cli.jujutsu.enable [
                  {
                    type = "command";
                    command = "jj new";
                  }
                ];
              }
            ];
          };
          includeCoAuthoredBy = false;
        };

        ".claude/CLAUDE.md".source = ./CLAUDE.md;

        # Copy hook scripts with executable permissions
        ".claude/hooks/common-helpers.sh" = {
          source = ./hooks/common-helpers.sh;
          executable = true;
        };

        ".claude/hooks/smart-lint.sh" = {
          source = ./hooks/smart-lint.sh;
          executable = true;
        };

        ".claude/hooks/smart-test.sh" = {
          source = ./hooks/smart-test.sh;
          executable = true;
        };

        ".claude/hooks/ntfy-notifier.sh" = {
          source = ./hooks/ntfy-notifier.sh;
          executable = true;
        };

        # Language-specific hook files
        ".claude/hooks/lint-go.sh" = {
          source = ./hooks/lint-go.sh;
          executable = true;
        };

        ".claude/hooks/test-go.sh" = {
          source = ./hooks/test-go.sh;
          executable = true;
        };

        ".claude/hooks/lint-tilt.sh" = {
          source = ./hooks/lint-tilt.sh;
          executable = true;
        };

        ".claude/hooks/test-tilt.sh" = {
          source = ./hooks/test-tilt.sh;
          executable = true;
        };

        # Integration helper script
        ".claude/hooks/integrate.sh" = {
          source = ./hooks/integrate.sh;
          executable = true;
        };

        # Copy documentation and examples (not executable)
        ".claude/hooks/README.md".source = ./hooks/README.md;
        ".claude/hooks/INTEGRATION.md".source = ./hooks/INTEGRATION.md;
        ".claude/hooks/QUICK_START.md".source = ./hooks/QUICK_START.md;
        ".claude/hooks/example-Justfile".source = ./hooks/example-Justfile;
        ".claude/hooks/example-claude-hooks-config.sh".source = ./hooks/example-claude-hooks-config.sh;
        ".claude/hooks/example-claude-hooks-ignore".source = ./hooks/example-claude-hooks-ignore;

        # Create necessary directories
        ".claude/.keep".text = "";
        ".claude/projects/.keep".text = "";
        ".claude/todos/.keep".text = "";
        ".claude/statsig/.keep".text = "";
        ".claude/commands/.keep".text = "";
      };
  };
}
