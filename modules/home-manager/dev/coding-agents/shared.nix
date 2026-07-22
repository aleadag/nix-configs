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

  # Activation helper for making store-managed configs writable and merging runtime additions
  mkWritableConfigActivation =
    {
      name,
      path,
      format ? "json",
    }:
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      set -euo pipefail

      config_path="${path}"
      backup_ext="''${HOME_MANAGER_BACKUP_EXT:-}"
      backup_path="$config_path''${backup_ext:+.$backup_ext}"
      tmp="$(mktemp)"

      if [ ! -e "$config_path" ]; then
        rm -f "$tmp"
      elif [ -n "$backup_ext" ] && [ -e "$backup_path" ]; then
        ${lib.getExe pkgs.yq-go} eval-all -p=${format} -o=${format} '. as $item ireduce ({}; . * $item)' "$backup_path" "$config_path" > "$tmp"

        if ! ${pkgs.diffutils}/bin/cmp -s "$backup_path" "$tmp"; then
          echo "Merged ${name} config changes:"
          ${pkgs.diffutils}/bin/diff -u "$backup_path" "$tmp" || true
        fi

        $DRY_RUN_CMD mv "$tmp" "$config_path"
        $DRY_RUN_CMD chmod 600 "$config_path"
        $DRY_RUN_CMD rm -f "$backup_path"
      elif [ -L "$config_path" ] && [[ "$(readlink "$config_path")" == /nix/store/* ]]; then
        if [[ -v DRY_RUN ]]; then
          echo "cat '$config_path' > '$tmp'"
        else
          cat "$config_path" > "$tmp"
        fi

        $DRY_RUN_CMD mv "$tmp" "$config_path"
        $DRY_RUN_CMD chmod 600 "$config_path"
      else
        rm -f "$tmp"
      fi
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
    mkWritableConfigActivation
    ;
}
