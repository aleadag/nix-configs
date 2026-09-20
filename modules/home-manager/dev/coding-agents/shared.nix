{
  config ? { },
  lib,
  pkgs,
  ...
}:

let
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
    jjStopHook
    makeSkillCommandAllowances
    permissions
    yeggeInstructions
    ;
}
