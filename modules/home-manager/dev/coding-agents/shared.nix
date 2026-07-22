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

  # Local skills (explicitly listed, each as a package)
  localSkills = {
    commit-message = import ./skills/commit-message { inherit config lib pkgs; };
  };

  # Plugins - defined once, used across tools
  plugins = [
    (pkgs.fetchFromGitHub {
      name = "beads-superpowers";
      owner = "DollarDill";
      repo = "beads-superpowers";
      rev = "v0.15.0";
      hash = "sha256-zT56CUynU+bjlC2F5LsfiFyX3aQ+OLNCMPxzq/Rwr4A=";
    })
  ];

  # Extract skills embedded inside plugins
  pluginSkills = lib.foldl' (
    acc: plugin:
    let
      skillsDir = plugin + "/skills";
    in
    if builtins.pathExists skillsDir then acc // loadSkills skillsDir else acc
  ) { } plugins;

  # All skills combined
  allSkills = jujutsuSkills // obsidianSkills // localSkills // pluginSkills;

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
    allSkills
    context
    defaultContext
    jujutsuSkills
    jjStopHook
    obsidianSkills
    localSkills
    pluginSkills
    plugins
    loadSkills
    permissions
    yeggeInstructions
    ;
}
