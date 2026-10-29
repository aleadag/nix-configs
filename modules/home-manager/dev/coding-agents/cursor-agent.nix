{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.cursor-agent;
in
{
  options.home-manager.dev.coding-agents.cursor-agent = {
    enable = lib.mkEnableOption "Cursor Agent" // {
      default = agentsCfg.enable;
    };

    package = lib.mkPackageOption pkgs.llm-agents "cursor-agent" {
      default = [ "cursor-agent" ];
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.dev.coding-agents.permissions = {
      allowedCommands = [
        "agent"
        "cursor-agent"
      ];
      commonExternalDirectories = [ "${config.home.homeDirectory}/.cursor" ];
    };

    home.packages = [ cfg.package ];
  };
}
