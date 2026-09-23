{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.herdr;
in
{
  options.home-manager.dev.coding-agents.herdr = {
    enable = lib.mkEnableOption "Herdr";
  };

  config = lib.mkIf cfg.enable {
    programs.herdr = {
      enable = true;
      package = pkgs.llm-agents.herdr;
      settings = { };
    };
  };
}
