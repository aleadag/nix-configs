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
    programs.claude-code = {
      enable = true;
      settings = {
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

    # Install additional packages
    home.packages = with pkgs; [
      just
      # Include cc-tools binaries
      cc-tools
    ];

    # Create and manage ~/.claude directory
    home.file =
      let
        # Shared commands from the vibe-coding directory
        sharedCommandFiles = builtins.readDir ./commands;
        sharedCommandEntries = lib.filterAttrs (
          name: type: type == "regular" && lib.hasSuffix ".md" name
        ) sharedCommandFiles;
        sharedCommandFileAttrs = lib.mapAttrs' (
          name: _: lib.nameValuePair ".claude/commands/${name}" { source = ./commands + "/${name}"; }
        ) sharedCommandEntries;
      in
      sharedCommandFileAttrs
      // {
        ".claude/CLAUDE.md".source = ./CONTEXT.md;

        # Create necessary directories
        ".claude/.keep".text = "";
        ".claude/projects/.keep".text = "";
        ".claude/todos/.keep".text = "";
        ".claude/statsig/.keep".text = "";
        ".claude/commands/.keep".text = "";
      };
  };
}

