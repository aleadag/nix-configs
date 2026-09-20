{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.antigravity-cli;
  inherit (agentsCfg.permissions)
    allowedShellCommands
    commonExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;
  allowedWriteDirectories = agentsCfg.permissions.finalAllowedWriteDirectories;
  homeDirectoryPattern = lib.escapeRegex config.home.homeDirectory;

  allowedCommands = map (command: "command(${command})") allowedShellCommands;
  deniedCommands = map (command: "command(${command})") deniedShellCommands;
  allowedNetworkReads = map (domain: "read_url(${domain})") commonNetworkDomains;
  allowedDirectoryPermissions = map (directory: "read_file(${directory})") commonExternalDirectories;
  allowedWriteDirectoryPermissions = map (
    directory: "write_file(${directory})"
  ) allowedWriteDirectories;
  deniedDirectoryPermissions = map (directory: "write_file(${directory})") commonExternalDirectories;

  allowedSkillPatterns = [
    "command(bash ${homeDirectoryPattern}/\\.gemini/antigravity-cli/skills/.*)"
    "command(${homeDirectoryPattern}/\\.gemini/antigravity-cli/skills/.*)"
    "command(bash ${homeDirectoryPattern}/\\.gemini/config/plugins/.*)"
    "command(${homeDirectoryPattern}/\\.gemini/config/plugins/.*)"
  ];

  wrapAntigravityPlugin =
    name: plugin:
    if builtins.pathExists (plugin + "/plugin.json") then
      plugin
    else if builtins.pathExists (plugin + "/gemini-extension.json") then
      pkgs.runCommand "agy-plugin-${name}" { } ''
        mkdir -p "$out"
        ln -s ${plugin}/* "$out/"
        cp "${plugin}/gemini-extension.json" "$out/plugin.json"
        if [ -f "${plugin}/hooks/hooks.json" ]; then
          sed 's/''${CLAUDE_PLUGIN_ROOT}/''${PLUGIN_ROOT}/g' \
            "${plugin}/hooks/hooks.json" > "$out/hooks.json"
        fi
      ''
    else
      throw "Antigravity plugin '${name}' has neither plugin.json nor gemini-extension.json";

  statusLineScript = pkgs.writeShellScript "agy-statusline" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.coreutils
      ]
    }:$PATH"
    ${builtins.readFile ./scripts/statusline.sh}
  '';
in
{
  options.home-manager.dev.coding-agents.antigravity-cli = {
    enable = lib.mkEnableOption "Antigravity CLI config" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' (
      name: plugin:
      lib.nameValuePair ".gemini/config/plugins/${name}" {
        source = wrapAntigravityPlugin name plugin;
      }
    ) agentsCfg.plugins;

    mutableConfig.files."${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json" = {
      source = config.home.file.".gemini/antigravity-cli/settings.json".source;
    };

    programs.antigravity-cli = {
      enable = true;
      package = pkgs.llm-agents.antigravity-cli;

      enableMcpIntegration = true;
      context = {
        CONTEXT = agentsCfg.context;
      };
      permissions = {
        allow =
          allowedCommands
          ++ allowedSkillPatterns
          ++ allowedDirectoryPermissions
          ++ allowedWriteDirectoryPermissions
          ++ allowedNetworkReads;
        deny = deniedCommands ++ deniedDirectoryPermissions;
      };
      inherit (agentsCfg) skills;
      settings = {
        model = "Gemini 3.8 Flash (High)";
        agentMode = "accept-edits";
        altScreenMode = "always";
        artifactReviewPolicy = "agent-decides";
        enableTelemetry = false;
        notifications = false;
        showFeedbackSurvey = false;
        statusLine = {
          command = "${statusLineScript}";
          enabled = true;
        };
        toolPermission = "proceed-in-sandbox";
      };
    };
  };
}
