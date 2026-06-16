{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.mcp;
  codingAgents = config.home-manager.dev.coding-agents;
in
{
  options.home-manager.dev.coding-agents.mcp = {
    enable = lib.mkEnableOption "mcp" // {
      default =
        codingAgents.claude-code.enable || codingAgents.codex.enable || codingAgents.gemini-cli.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = {
      enable = true;
      servers = {
        context7 = {
          command = lib.getExe pkgs.context7-mcp;
        };
      };
    };
  };
}
