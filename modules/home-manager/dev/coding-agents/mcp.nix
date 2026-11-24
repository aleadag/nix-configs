{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.mcp;
in
{
  options.home-manager.dev.coding-agents.mcp = {
    enable = lib.mkEnableOption "mcp" // {
      default = config.home-manager.dev.coding-agents.enable;
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
