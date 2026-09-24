{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents;

  scriptExtensions = [ "sh" ];
  portableSkillScriptPathPattern = "[A-Za-z0-9._/-]+";

  isScriptFile =
    path:
    let
      fileName = baseNameOf path;
      splitName = lib.splitString "." fileName;
      ext = if builtins.length splitName > 1 then lib.last splitName else "";
    in
    lib.elem ext scriptExtensions && lib.hasPrefix "#!" (builtins.readFile path);

  findScriptsInDir =
    baseRel: dirPath:
    if builtins.pathExists dirPath then
      let
        entries = builtins.readDir dirPath;
        regularFiles = builtins.attrNames (lib.filterAttrs (_: type: type == "regular") entries);
      in
      lib.concatMap (
        file:
        let
          fullPath = dirPath + "/${file}";
          relPath = if baseRel == "" then file else "${baseRel}/${file}";
        in
        if isScriptFile fullPath then [ relPath ] else [ ]
      ) regularFiles
    else
      [ ];

  discoverSkillScripts =
    skills:
    lib.unique (
      lib.concatLists (
        lib.mapAttrsToList (
          skillName: skillPath:
          (findScriptsInDir skillName skillPath)
          ++ (findScriptsInDir "${skillName}/scripts" (skillPath + "/scripts"))
        ) skills
      )
    );

  validateSkillScriptRelativePaths =
    paths:
    let
      invalidPaths = lib.filter (path: builtins.match portableSkillScriptPathPattern path == null) paths;
    in
    if invalidPaths == [ ] then
      paths
    else
      throw "Unsafe standalone skill script relative path(s): ${lib.concatStringsSep ", " invalidPaths}. Paths must contain only ASCII letters, digits, '.', '_', '-', and '/'.";

in
{
  imports = [
    ./antigravity-cli.nix
    ./beads.nix
    ./codex.nix
    ./coding-brain.nix
    ./herdr.nix
    ./opencode.nix
    ./pi.nix
    ./mcp.nix
    ./permissions.nix
    flake.inputs.coding-brain.homeManagerModules.default
  ];

  options.home-manager.dev.coding-agents = {
    enable = lib.mkEnableOption "coding agent config" // {
      default = config.home-manager.dev.enable;
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Skills to provide across coding agents (mapping of skill name to skill directory path)";
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Attribute set of coding agent plugins providing bundled skills, lifecycle hooks, and manifests.";
    };

    skillScriptRelativePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Discovered relative script paths across all enabled skills";
    };

    context = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = builtins.readFile ./CONTEXT.md;
      description = "Shared coding agent context";
    };

  };

  config = lib.mkMerge [
    {
      home-manager.dev.coding-agents.skillScriptRelativePaths = validateSkillScriptRelativePaths (
        discoverSkillScripts cfg.skills
      );
    }
    (lib.mkIf cfg.enable {
      home-manager.dev.coding-agents.skills = {
        commit-message = ./skills/commit-message;
      };

      home.packages = with pkgs; [
        ctx7
        defuddle
      ];
    })
  ];
}
