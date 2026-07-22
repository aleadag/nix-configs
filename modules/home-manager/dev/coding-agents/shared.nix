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
      rev = "d48ccb9ea91a1ffa485965c7efbaa98f63e8bfbe";
      hash = "sha256-MHgKiCE5rn4L3ZcdTiDTeTXTo81dFBXccTR7GHbrlsk=";
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
  permissions = import ./permissions.nix { };

  # Yegge instructions for tools that support agent profiles
  yeggeInstructions = builtins.readFile ./agents/yegge.md;
in
{
  inherit
    allSkills
    context
    jujutsuSkills
    obsidianSkills
    localSkills
    pluginSkills
    plugins
    loadSkills
    permissions
    yeggeInstructions
    ;
}
