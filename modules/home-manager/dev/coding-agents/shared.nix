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

  # All skills combined
  allSkills = jujutsuSkills // obsidianSkills // localSkills;

  # Shared plugins - defined once, used by both tools
  sharedPlugins = [
    (pkgs.fetchFromGitHub {
      name = "beads-superpowers";
      owner = "DollarDill";
      repo = "beads-superpowers";
      rev = "d48ccb9ea91a1ffa485965c7efbaa98f63e8bfbe";
      hash = "sha256-MHgKiCE5rn4L3ZcdTiDTeTXTo81dFBXccTR7GHbrlsk=";
    })
  ];

  # Shared context file
  sharedContext = ./CONTEXT.md;

  # Yegge instructions for tools that support agent profiles
  yeggeInstructions = builtins.readFile ./agents/yegge.md;
in
{
  inherit
    allSkills
    jujutsuSkills
    obsidianSkills
    localSkills
    loadSkills
    sharedPlugins
    sharedContext
    yeggeInstructions
    ;
}
