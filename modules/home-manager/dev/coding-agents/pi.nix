{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.pi-coding-agent;
  piCfg = config.programs.pi-coding-agent;
in
{
  options.home-manager.dev.coding-agents.pi-coding-agent = {
    enable = lib.mkEnableOption "Pi Coding Agent" // {
      default = agentsCfg.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      file = lib.mapAttrs' (
        name: source:
        lib.nameValuePair "${piCfg.configDir}/skills/${name}" {
          inherit source;
        }
      ) agentsCfg.skills;

      sessionVariables.PI_SKIP_VERSION_CHECK = "1";
    };

    programs.pi-coding-agent = {
      enable = true;
      package = pkgs.llm-agents.pi;
      inherit (agentsCfg) context;
      settings = {
        enableAnalytics = false;
        enableInstallTelemetry = false;
      };
    };
  };
}
