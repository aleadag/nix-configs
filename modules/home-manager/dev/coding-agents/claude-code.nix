{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.claude-code;

  inherit (agentsCfg) strataHost strataModel;
  strataBaseUrl = "http://${strataHost}:${toString agentsCfg.strataPort}";

  inherit (agentsCfg.permissions)
    allowedShellCommands
    finalExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;

  basicToolPermissions = [
    "Read"
    "Edit"
    "Write"
    "Glob"
    "Grep"
    "Agent"
  ];
  allowedBashPermissions = map (command: "Bash(${command}:*)") allowedShellCommands;
  allowedNetworkPermissions = map (domain: "WebFetch(domain:${domain})") (
    commonNetworkDomains ++ [ strataHost ]
  );
  deniedBashPermissions = map (command: "Bash(${command}:*)") deniedShellCommands;
  # Claude Code matches file-path rules with `Edit(...)` only; `Write(<path>)`
  # rules never match, so the `Edit` form is what guards these directories.
  readOnlyDirectoryPermissions = map (directory: "Edit(${directory}/**)") finalExternalDirectories;
in
{
  options.home-manager.dev.coding-agents.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI tool" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      inherit (agentsCfg) context;
      inherit (agentsCfg) skills;
      inherit (agentsCfg) plugins;
      settings = {
        env = {
          ANTHROPIC_BASE_URL = strataBaseUrl;
          ANTHROPIC_AUTH_TOKEN = "strata";
          ANTHROPIC_MODEL = strataModel;
          ANTHROPIC_DEFAULT_HAIKU_MODEL = strataModel;
          ANTHROPIC_DEFAULT_SONNET_MODEL = strataModel;
          ANTHROPIC_DEFAULT_OPUS_MODEL = strataModel;
          BASH_DEFAULT_TIMEOUT_MS = "300000";
          BASH_MAX_TIMEOUT_MS = "600000";
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
          USE_BUILTIN_RIPGREP = "0";
        };

        includeCoAuthoredBy = false;
        permissions = {
          allow = allowedBashPermissions ++ allowedNetworkPermissions ++ basicToolPermissions;
          deny = deniedBashPermissions ++ readOnlyDirectoryPermissions;
          additionalDirectories = finalExternalDirectories;
        };
        sandbox = {
          enabled = true;
          failIfUnavailable = true;
          allowUnsandboxedCommands = false;
          autoAllowBashIfSandboxed = false;
          network = {
            allowedDomains = commonNetworkDomains ++ [ strataHost ];
            strictAllowlist = true;
          };
        };
      };
    };
  };
}
