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
    enable = lib.mkEnableOption "Herdr" // {
      default = config.home-manager.dev.coding-agents.enable;
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.package lib.types.path);
      default = [ ];
      description = "List of Herdr plugin packages or directories to link into Herdr on activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.dev.coding-agents = {
      skills.herdr = pkgs.llm-agents.herdr.src + "/skills/herdr";
    };

    home.activation.unlinkHerdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink herdr-navigator || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink herdr.collie || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink herdr-beads || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink pi-herdr-subagents || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink steward-argv || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink agent-steward-router || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink agent-steward || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink agent-steward-approval || true
      $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin unlink agent-steward-stop || true
    '';

    home.activation.linkHerdrPlugins = lib.mkIf (cfg.plugins != [ ]) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${lib.concatMapStringsSep "\n" (plugin: ''
          _plugin_path="${plugin}"
          if [ -f "$_plugin_path/herdr-plugin.toml" ]; then
            $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin link "$_plugin_path" --enabled || true
          elif [ -d "$_plugin_path/libexec/herdr/plugins" ]; then
            for manifest in "$_plugin_path"/libexec/herdr/plugins/*/herdr-plugin.toml; do
              if [ -f "$manifest" ]; then
                $DRY_RUN_CMD ${lib.getExe config.programs.herdr.package} plugin link "$(dirname "$manifest")" --enabled || true
              fi
            done
          fi
        '') cfg.plugins}
      ''
    );

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
