{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.skills;

  mergedSkills = pkgs.runCommand "merged-skills" { } ''
    mkdir -p $out
    # Copy local skills
    if [ -d ${./skills} ]; then
      cp -r ${./skills}/* $out/
    fi

    # Copy obsidian-skills from flake input if enabled
    if [ "${if cfg.obsidianSkills.enable then "1" else "0"}" = "1" ]; then
      echo "Copying all obsidian skills from ${flake.inputs.obsidian-skills}"
      cp -r ${flake.inputs.obsidian-skills}/. $out/
    fi
  '';
in
{
  options.home-manager.dev.coding-agents.skills = {
    enable = lib.mkEnableOption "coding agent skills" // {
      default = config.home-manager.dev.enable;
    };
    obsidianSkills.enable = lib.mkEnableOption "Obsidian skills" // {
      default = config.home-manager.desktop.obsidian.enable;
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = mergedSkills;
      description = "The merged skills derivation.";
    };
  };

  config = lib.mkIf cfg.enable {
    # the skills folder can be a symlink, but SKILL.md cannot be a symlink:
    # XXX: https://github.com/openai/codex/issues/10470
    home.file.".agents/skills".source = cfg.package;

    home.packages = lib.optionals cfg.obsidianSkills.enable [
      # defuddle-cli is broken for now
      # pkgs.defuddle-cli
    ];
  };
}
