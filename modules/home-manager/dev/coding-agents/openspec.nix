{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.openspec;
in
{
  options.home-manager.dev.coding-agents.openspec = {
    enable = lib.mkEnableOption "Openspec config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.llm-agents.openspec ];
      sessionVariables.OPENSPEC_TELEMETRY = "0";
    };
  };
}
