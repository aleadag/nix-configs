{
  config,
  lib,
  libEx,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.pi-coding-agent;
  piCfg = config.programs.pi-coding-agent;

  pluginSkills = lib.concatMapAttrs (
    _: plugin:
    lib.optionalAttrs (builtins.pathExists (plugin + "/skills")) (libEx.loadSkills (plugin + "/skills"))
  ) agentsCfg.plugins;
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
      ) (pluginSkills // agentsCfg.skills);

      sessionVariables.PI_SKIP_VERSION_CHECK = "1";
    };

    programs.pi-coding-agent = {
      enable = true;
      package = pkgs.llm-agents.pi;
      inherit (agentsCfg) context;
      settings = {
        defaultProvider = "xai";
        defaultModel = "grok-4.7";
        defaultThinkingLevel = "xhigh";
        enableAnalytics = false;
        enableInstallTelemetry = false;
        packages = lib.mapAttrsToList (_: source: {
          source = "${source}";
          skills = [ ];
        }) agentsCfg.plugins;
      };
    };
  };
}
