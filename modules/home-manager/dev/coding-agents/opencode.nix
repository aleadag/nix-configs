{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.opencode;
  shared = import ./shared.nix {
    inherit
      config
      flake
      lib
      pkgs
      ;
  };
  inherit (shared.permissions)
    allowedShellCommands
    commonExternalDirectories
    deniedShellCommands
    ;

  bashPattern = command: "${command}*";
  allowPatterns = map bashPattern allowedShellCommands;
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
      context = shared.defaultContext;
      settings = {
        autoshare = false;
        autoupdate = false;
        model = "deepseek/deepseek-v4-pro";
        plugin = [ shared.plugins.beads-superpowers ];
        permission.bash = bashPermissions;
        permission.external_directory = externalDirectoryPermissions;
        permission.edit = externalDirectoryReadOnly;
      };
      skills = shared.guardedSkills;
    };
  };
}
