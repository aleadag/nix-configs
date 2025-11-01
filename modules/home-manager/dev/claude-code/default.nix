{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.claude-code;
  # Get cc-tools binaries from the flake
  cc-tools = flake.inputs.cc-tools.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.home-manager.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI tool" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    # Install Claude Code package and ccusage
    home.packages =
      with pkgs;
      [
        claude-code
        just
        # Include cc-tools binaries
        cc-tools
      ]
      ++ lib.optionals (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64) [
        # FHS environment for running Playwright browsers (x86_64 Linux only)
        steam-run
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
          # Use RAM-based cache on Linux (/dev/shm) or regular tmp on macOS
          CLAUDE_STATUSLINE_CACHE_DIR = if pkgs.stdenv.isDarwin then "/tmp" else "/dev/shm";
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
                  command = "${cc-tools}/bin/cc-tools-validate";
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

        # Create necessary directories
        ".claude/.keep".text = "";
        ".claude/projects/.keep".text = "";
        ".claude/todos/.keep".text = "";
        ".claude/statsig/.keep".text = "";
        ".claude/commands/.keep".text = "";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        # Playwright MCP wrapper for steam-run (Linux only)
        ".claude/playwright-mcp-wrapper.sh" = {
          source = ./playwright-headless-wrapper.sh;
          executable = true;
        };
      };
  };
}
