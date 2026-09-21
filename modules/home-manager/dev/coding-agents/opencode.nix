{
  config,
  lib,
  pkgs,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  cfg = agentsCfg.opencode;
  inherit (agentsCfg.permissions)
    allowedShellCommands
    commonExternalDirectories
    deniedShellCommands
    ;

  bashPattern = command: "${command}*";
  skillCommands = lib.concatMap (rel: [
    "${config.home.homeDirectory}/.config/opencode/skills/${rel}"
    "bash ${config.home.homeDirectory}/.config/opencode/skills/${rel}"
  ]) agentsCfg.skillScriptRelativePaths;
  skillCommandPatterns = lib.concatMap (command: [
    command
    "${command} *"
  ]) skillCommands;
  allowPatterns = map bashPattern allowedShellCommands ++ skillCommandPatterns;
  externalDirectoryPermissions = lib.genAttrs (map (
    directory: "${directory}/**"
  ) commonExternalDirectories) (lib.const "allow");
  externalDirectoryReadOnly = lib.genAttrs (map (
    directory: "${directory}/**"
  ) commonExternalDirectories) (lib.const "deny");

  # Last matching rule wins: catch-all first, allows next, denies last.
  bashPermissions =
    lib.listToAttrs (
      map (
        command: lib.nameValuePair (bashPattern command) (lib.hm.dag.entryAfter [ "*" ] "allow")
      ) allowedShellCommands
    )
    // lib.listToAttrs (
      map (
        command: lib.nameValuePair command (lib.hm.dag.entryAfter [ "*" ] "allow")
      ) skillCommandPatterns
    )
    // lib.listToAttrs (
      map (
        command:
        lib.nameValuePair (bashPattern command) (lib.hm.dag.entryAfter ([ "*" ] ++ allowPatterns) "deny")
      ) deniedShellCommands
    )
    // {
      "*" = "ask";
    };
in
{
  options.home-manager.dev.coding-agents.opencode = {
    enable = lib.mkEnableOption "OpenCode CLI tool" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.llm-agents.opencode;
      inherit (agentsCfg) context;
      settings = {
        autoshare = false;
        autoupdate = false;
        model = "deepseek/deepseek-v4-pro";
        plugin = lib.attrValues agentsCfg.plugins;
        permission.bash = bashPermissions;
        permission.external_directory = externalDirectoryPermissions;
        permission.edit = externalDirectoryReadOnly;
      };
      inherit (agentsCfg) skills;
    };
  };
}
