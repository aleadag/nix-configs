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
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = {
      enable = true;
      servers = {
        nixos = {
          command = lib.getExe pkgs.mcp-nixos;
        };
      };
    };
  };
}
