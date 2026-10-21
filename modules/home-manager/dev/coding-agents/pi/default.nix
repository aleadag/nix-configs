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
    assertions = [
      {
        assertion = config.home-manager.sops.enable;
        message = "Pi DeepSeek integration requires home-manager.sops.enable.";
      }
    ];

    sops.secrets.deepseek_api_key = {
      key = "deepseek_api_key";
      mode = "0600";
    };

    home = {
      file =
        lib.mapAttrs' (
          name: source:
          lib.nameValuePair "${piCfg.configDir}/skills/${name}" {
            inherit source;
          }
        ) (pluginSkills // agentsCfg.skills)
        // lib.optionalAttrs agentsCfg.herdr.enable {
          "${piCfg.configDir}/skills/subagents".source = ./skills/subagents;
        };

      sessionVariables.PI_SKIP_VERSION_CHECK = "1";
    };

    programs.pi-coding-agent = {
      enable = true;
      package = pkgs.llm-agents.pi;
      inherit (agentsCfg) context;
      models.providers.deepseek = {
        baseUrl = "https://api.deepseek.com";
        api = "openai-completions";
        apiKey = "!${pkgs.coreutils}/bin/cat ${lib.escapeShellArg config.sops.secrets.deepseek_api_key.path}";
        compat = {
          requiresReasoningContentOnAssistantMessages = true;
          thinkingFormat = "deepseek";
          reasoningEffortMap = {
            minimal = "high";
            low = "high";
            medium = "high";
            high = "high";
            xhigh = "max";
          };
        };
        models = [
          {
            id = "deepseek-v4-pro";
            name = "DeepSeek V4 Pro";
            contextWindow = 1000000;
            maxTokens = 384000;
            input = [ "text" ];
            reasoning = true;
            cost = {
              input = 1.74;
              output = 3.48;
              cacheRead = 0.145;
              cacheWrite = 0;
            };
          }
          {
            id = "deepseek-v4-flash";
            name = "DeepSeek V4 Flash";
            contextWindow = 1000000;
            maxTokens = 384000;
            input = [ "text" ];
            reasoning = true;
            cost = {
              input = 0.14;
              output = 0.28;
              cacheRead = 0.028;
              cacheWrite = 0;
            };
          }
        ];
      };
      settings = {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-6.1-sol";
        defaultThinkingLevel = "high";
        defaultTools = [ "+codemode" ];
        enableAnalytics = false;
        enableInstallTelemetry = false;
        enabledModels = [
          "grok-4.6"
          "gpt-6*"
          "deepseek/deepseek-v4-*"
        ];
        packages = lib.mapAttrsToList (_: source: {
          source = "${source}";
          skills = [ ];
        }) agentsCfg.plugins;
      };
    };
  };
}
