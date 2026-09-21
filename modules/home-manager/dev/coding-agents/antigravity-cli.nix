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

  allowedCommands = map (command: "command(${command})") allowedShellCommands;
  deniedCommands = map (command: "command(${command})") deniedShellCommands;
  allowedNetworkReads = map (domain: "read_url(${domain})") commonNetworkDomains;
  allowedDirectoryPermissions = map (directory: "read_file(${directory})") commonExternalDirectories;
  allowedWriteDirectoryPermissions = map (
    directory: "write_file(${directory})"
  ) allowedWriteDirectories;
  deniedDirectoryPermissions = map (directory: "write_file(${directory})") commonExternalDirectories;

  allowedSkillPatterns = lib.concatMap (
    rel:
    let
      skillPath = lib.escapeRegex "${config.home.homeDirectory}/.gemini/antigravity-cli/skills/${rel}";
    in
    [
      "command(regex:${skillPath})"
      "command(regex:bash ${skillPath})"
    ]
  ) agentsCfg.skillScriptRelativePaths;
  allowedPluginHookPatterns = lib.concatMap (
    plugin:
    let
      hookPath = "${plugin}/hooks/run-hook.cmd";
      escapedHookPath = lib.escapeRegex hookPath;
    in
    lib.optionals (builtins.pathExists hookPath) [
      "command(regex:${escapedHookPath} session-start)"
      "command(regex:bash ${escapedHookPath} session-start)"
    ]
  ) (lib.attrValues agentsCfg.plugins);
  deniedPluginHookPatterns = lib.concatMap (
    plugin:
    let
      hookPath = "${plugin}/hooks/run-hook.cmd";
      escapedHookPath = lib.escapeRegex hookPath;
    in
    lib.optionals (builtins.pathExists hookPath) [
      "command(regex:${escapedHookPath} session-start .*)"
      "command(regex:bash ${escapedHookPath} session-start .*)"
    ]
  ) (lib.attrValues agentsCfg.plugins);

  wrapAntigravityPlugin =
    name: plugin:
    let
      hasPluginManifest = builtins.pathExists (plugin + "/plugin.json");
      hasGeminiManifest = builtins.pathExists (plugin + "/gemini-extension.json");
      hasHooksManifest = builtins.pathExists (plugin + "/hooks/hooks.json");
    in
    if hasPluginManifest && !hasHooksManifest then
      plugin
    else if hasPluginManifest || hasGeminiManifest then
      pkgs.runCommandLocal "agy-plugin-${name}" { } ''
        mkdir -p "$out"
        ln -s ${plugin}/* "$out/"
        ${lib.optionalString (!hasPluginManifest) ''
          cp "${plugin}/gemini-extension.json" "$out/plugin.json"
        ''}
        ${lib.optionalString hasHooksManifest ''
          sed 's|''${CLAUDE_PLUGIN_ROOT}|${plugin}|g' \
            "${plugin}/hooks/hooks.json" > "$out/hooks.json"
        ''}
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
      context = {
        CONTEXT = agentsCfg.context;
      };
      permissions = {
        allow =
          allowedCommands
          ++ allowedSkillPatterns
          ++ allowedPluginHookPatterns
          ++ allowedDirectoryPermissions
          ++ allowedWriteDirectoryPermissions
          ++ allowedNetworkReads;
        deny = deniedCommands ++ deniedPluginHookPatterns ++ deniedDirectoryPermissions;
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
