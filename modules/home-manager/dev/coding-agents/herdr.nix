{
  config,
  flake,
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
    home-manager.dev.coding-agents.skills.herdr = flake.inputs.herdr-src + "/skills/herdr";

    programs.herdr = {
      enable = true;
      package = pkgs.llm-agents.herdr;
      settings = {
        onboarding = false;
        theme = {
          name = "terminal";
          auto_switch = false;
          custom = {
            active_row_bg = "#${config.lib.stylix.colors.base02}";
            selection_bg = "#${config.lib.stylix.colors.base01}";
          };
        };
      };
    };
  };
}
