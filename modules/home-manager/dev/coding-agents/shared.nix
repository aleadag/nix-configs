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

in
{
  inherit
    context
    defaultContext
    guardedSkills
    guardedSkillsWithPlugins
    jujutsuSkills
    jjStopHook
    obsidianSkills
    localSkills
    pluginSkills
    plugins
    pluginSources
    loadSkills
    permissions
    yeggeInstructions
    ;
}
