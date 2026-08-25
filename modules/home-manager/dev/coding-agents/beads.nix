{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.beads;
in
{
  options.home-manager.dev.coding-agents.beads = {
    enable = lib.mkEnableOption "Beads issue tracker config" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = with pkgs.llm-agents; [
        beads
        mardi-gras
      ];
      sessionVariables = {
        BD_DISABLE_METRICS = "1";
        DO_NOT_TRACK = "1";
      };
    };
  };
}
