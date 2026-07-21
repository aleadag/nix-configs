{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.claude-code;
  sharedPermissions = import ./permissions.nix { inherit lib; };
  shared = import ./shared.nix { inherit flake lib pkgs; };

  claudeZai = pkgs.writeShellScriptBin "claude-zai" ''
    export ANTHROPIC_BASE_URL="$(cat ${config.sops.secrets.claude_zai_base_url.path})"
    export ANTHROPIC_AUTH_TOKEN="$(cat ${config.sops.secrets.claude_zai_auth_token.path})"
    exec ${config.programs.claude-code.package}/bin/claude "$@"
  '';
in
{
  options.home-manager.dev.coding-agents.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI tool" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.claude_zai_base_url = { };
    sops.secrets.claude_zai_auth_token = { };

    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      context = shared.sharedContext;
      plugins = shared.sharedPlugins;
      skills = lib.optionalAttrs config.home-manager.cli.jujutsu.enable shared.jujutsuSkills // shared.obsidianSkills // shared.localSkills;
      agents.yegge = ''
        ---
        name: yegge
        description: Primary session orchestrator that triages requests and coordinates non-trivial work through the applicable skills.
        model: inherit
        ---

        ${shared.yeggeInstructions}
      '';
      settings = {
        env = {
          BASH_DEFAULT_TIMEOUT_MS = "300000";
          BASH_MAX_TIMEOUT_MS = "600000";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          USE_BUILTIN_RIPGREP = "0";
        };

        hooks = {
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
        permissions = {
          allow = sharedPermissions.claudeFullPermissions;
          deny = sharedPermissions.claudeDeniedBashPermissions;
        };
      };
    };

    home.packages = [ claudeZai ];
  };
}
