{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.claude-code;
  sharedPermissions = import ./permissions.nix { inherit lib; };
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
      context = ./CONTEXT.md;
      plugins = [
        (pkgs.fetchFromGitHub {
          name = "beads-superpowers";
          owner = "DollarDill";
          repo = "beads-superpowers";
          rev = "d48ccb9ea91a1ffa485965c7efbaa98f63e8bfbe";
          hash = "sha256-MHgKiCE5rn4L3ZcdTiDTeTXTo81dFBXccTR7GHbrlsk=";
        })
      ];
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
          allow = sharedPermissions.claudeAllowedBashPermissions ++ [
            "Read"
            "Edit"
            "Write"
            "Glob"
            "Grep"
            "Agent"
          ];
          deny = [
            "Bash(rm -rf:*)"
            "Bash(git push --force:*)"
            "Bash(git reset --hard:*)"
            "Bash(git clean -f:*)"
            "Bash(terraform apply:*)"
            "Bash(terraform destroy:*)"
            "Bash(sbt publish:*)"
          ];
        };
      };
    };

    home.packages = [ claudeZai ];
  };
}
