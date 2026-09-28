{
  config,
  flake,
  lib,
  libEx,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.pi-coding-agent;
  piCfg = config.programs.pi-coding-agent;
  herdrSource = flake.inputs.pi-herdr-subagents;
  herdrPlugin = pkgs.runCommandLocal "pi-herdr-subagents-plugin" { } ''
    mkdir -p "$out"
    cp -r ${herdrSource}/herdr-plugin/. "$out/"
  '';

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
    home-manager.dev.coding-agents.herdr.plugins = lib.mkIf agentsCfg.herdr.enable [ herdrPlugin ];

    home = {
      file =
        lib.mapAttrs' (
          name: source:
          lib.nameValuePair "${piCfg.configDir}/skills/${name}" {
            inherit source;
          }
        ) (pluginSkills // agentsCfg.skills)
        // lib.optionalAttrs agentsCfg.herdr.enable {
          "${piCfg.configDir}/agents/planner.md".source = ./pi/agents/planner.md;
          "${piCfg.configDir}/agents/worker.md".source = ./pi/agents/worker.md;
          "${piCfg.configDir}/agents/reviewer.md".source = ./pi/agents/reviewer.md;
        };

      sessionVariables.PI_SKIP_VERSION_CHECK = "1";
    };

    programs.pi-coding-agent = {
      enable = true;
      package = pkgs.llm-agents.pi;
      context =
        agentsCfg.context + lib.optionalString agentsCfg.herdr.enable (builtins.readFile ./pi/HERDR.md);
      settings = {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-6-sol";
        defaultThinkingLevel = "medium";
        enableAnalytics = false;
        enableInstallTelemetry = false;
        enabledModels = [
          "grok-4.6"
          "gpt-6-*"
        ];
        packages =
          lib.optionals agentsCfg.herdr.enable [
            {
              source = "${herdrSource}";
              skills = [ ];
            }
          ]
          ++ lib.mapAttrsToList (_: source: {
            source = "${source}";
            skills = [ ];
          }) agentsCfg.plugins;
      };
    };
  };
}
