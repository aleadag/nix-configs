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

        update = {
          version_check = false;
          manifest_check = false;
        };

        # home-manager owns ~/.ssh/config; keep herdr from writing it too.
        remote.manage_ssh_config = false;

        theme = {
          name = "terminal";
          auto_switch = false;
          custom = {
            active_row_bg = "#${config.lib.stylix.colors.base02}";
            selection_bg = "#${config.lib.stylix.colors.base01}";
          };
        };

        ui = {
          agent_panel_sort = "priority";
          prompt_new_tab_name = false;
        };

        session.resume_agents_on_restore = true;
        experimental.kitty_graphics = true;
      };
    };
  };
}
