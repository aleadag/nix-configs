{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.codex;
  sharedPermissions = import ./permissions.nix { inherit lib; };
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
in
{
  options.home-manager.dev.coding-agents.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mcp-nixos ];
    home.file = {
      ".codex/rules/basic.rules".text =
        lib.concatMapStringsSep "\n" renderPrefixRule sharedPermissions.codexAllowedPrefixRules + "\n";
      # the skills folder can be a symlink, but SKILL.md cannot be a symlink:
      # XXX: https://github.com/openai/codex/issues/10470
      ".agents/skills".source = ./skills;
    };

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      package = pkgs.llm-agents.codex;
      settings = {
        approval_policy = "on-request";
        analytics.enabled = false;
        check_for_update_on_startup = false;
        model = "gpt-5.4";
        sandbox_mode = "workspace-write";
        projects = {
          "${config.home.homeDirectory}/hacking/aleadag/nix-configs" = {
            trust_level = "trusted";
          };
          "${config.home.homeDirectory}/hacking/tiwater/lucid" = {
            trust_level = "trusted";
          };
        };
      };
      custom-instructions = builtins.readFile ./CONTEXT.md;
      skills = { };
    };
  };
}
