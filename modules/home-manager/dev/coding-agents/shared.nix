{
  config ? { },
  flake,
  lib,
  pkgs,
  ...
}:

let
  # Load skills from a directory - returns an attrset of name -> path
  loadSkills =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = dir + "/${name}";
      }) (builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries))
    );

  # Shared skills from flake inputs
  jujutsuSkills = loadSkills flake.inputs.jujutsu-skills;
  obsidianSkills = loadSkills flake.inputs.obsidian-skills;

  # Local skills (explicitly listed)
  localSkills = {
    commit-message = ./skills/commit-message;
  };

  # Plugins - defined once, used across tools
  plugins = {
    beads-superpowers = pkgs.fetchFromGitHub {
      name = "beads-superpowers";
      owner = "DollarDill";
      repo = "beads-superpowers";
      rev = "v0.15.0";
      hash = "sha256-zT56CUynU+bjlC2F5LsfiFyX3aQ+OLNCMPxzq/Rwr4A=";
    };
  };
  pluginSources = lib.attrValues plugins;

  # Extract skills embedded inside plugins
  pluginSkills = lib.foldl' (
    acc: plugin:
    let
      skillsDir = plugin + "/skills";
    in
    if builtins.pathExists skillsDir then acc // loadSkills skillsDir else acc
  ) { } pluginSources;

  # Skills gated by feature flags, for tools that should only see enabled features
  guardedSkills =
    lib.optionalAttrs config.home-manager.cli.jujutsu.enable jujutsuSkills
    // lib.optionalAttrs config.home-manager.desktop.obsidian.enable obsidianSkills
    // localSkills;
  guardedSkillsWithPlugins = guardedSkills // pluginSkills;

  # Context file
  context = ./CONTEXT.md;

  # Shared permissions
  permissions = import ./permissions.nix { inherit config lib pkgs; };

  # Yegge instructions for tools that support agent profiles
  yeggeInstructions = builtins.readFile ./agents/yegge.md;

  # Default context combining base CONTEXT.md and Yegge orchestrator instructions
  defaultContext = ''
    ${builtins.readFile ./CONTEXT.md}

    ${yeggeInstructions}
  '';

  # Jujutsu stop hook script that avoids creating empty revisions
  jjStopHook = pkgs.writeShellScript "coding-agents-jj-stop-hook" ''
    if jj root >/dev/null 2>&1 && [ -n "$(jj diff --summary 2>/dev/null)" ]; then
      jj new >/dev/null 2>&1 || true
    fi
    printf '%s\n' '{"continue":true}'
  '';

  # Discovers all executable scripts (files starting with a shebang #!) across a skill set
  discoverSkillScripts =
    skills:
    let
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
              isScript = lib.hasPrefix "#!" (builtins.readFile fullPath);
            in
            if isScript then [ relPath ] else [ ]
          ) regularFiles
        else
          [ ];
    in
    lib.concatLists (
      lib.mapAttrsToList (
        skillName: skillPath:
        (findScriptsInDir skillName skillPath)
        ++ (findScriptsInDir "${skillName}/scripts" (skillPath + "/scripts"))
      ) skills
    );

  # Helper to generate shell command allowances (both direct and via bash) for an agent's skills directory
  makeSkillCommandAllowances =
    baseSkillsDir: skills:
    lib.concatMap (
      relPath:
      let
        fullPath = "${baseSkillsDir}/${relPath}";
      in
      [
        "bash ${fullPath}"
        fullPath
      ]
    ) (discoverSkillScripts skills);
in
{
  inherit
    context
    defaultContext
    discoverSkillScripts
    guardedSkills
    guardedSkillsWithPlugins
    jujutsuSkills
    jjStopHook
    obsidianSkills
    localSkills
    makeSkillCommandAllowances
    pluginSkills
    plugins
    pluginSources
    loadSkills
    permissions
    yeggeInstructions
    ;
}
