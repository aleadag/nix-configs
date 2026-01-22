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
    sops.secrets.anthropic_base_url = { };
    sops.secrets.anthropic_api_key = { };

    programs.claude-code = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "claude-code-wrapped";
        paths = [ pkgs.claude-code ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/claude \
            --run 'export ANTHROPIC_BASE_URL="$(cat ${config.sops.secrets.anthropic_base_url.path})"' \
            --run 'export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.anthropic_api_key.path})"'
        '';
      };
      commandsDir = ./commands;
      memory.source = ./CONTEXT.md;
      settings = {
        env = {
          BASH_DEFAULT_TIMEOUT_MS = "300000";
          BASH_MAX_TIMEOUT_MS = "600000";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          USE_BUILTIN_RIPGREP = "0";
        };

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
  };
}
