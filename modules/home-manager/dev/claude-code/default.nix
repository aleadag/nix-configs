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

    mutableConfig.files = {
      # Claude Code settings which requires writabble
      "${config.home.homeDirectory}/.claude/settings.json" = {
        env = {
          BASH_DEFAULT_TIMEOUT_MS = "300000";
          BASH_MAX_TIMEOUT_MS = "600000";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          TZ = "America/Los_Angeles";
          USE_BUILTIN_RIPGREP = "0";
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

        statusLine = {
          type = "command";
          command = "~/.claude/hooks/statusline.sh";
          padding = 0;
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
    };

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

        # Integration helper script
        ".claude/hooks/integrate.sh" = {
          source = ./hooks/integrate.sh;
          executable = true;
        };

        # Status line script
        ".claude/hooks/statusline.sh" = {
          source = ./hooks/statusline.sh;
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
