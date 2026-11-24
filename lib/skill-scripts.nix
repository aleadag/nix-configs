{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

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
in
rec {
  # Discover relative paths of executable (shebang) skill scripts for a
  # mapping of skill name to skill directory.
  #
  # nix-repl> discoverSkillScripts { commit-message = ./skills/commit-message; }
  # [ "commit-message/scripts/xyz.sh" ]
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

  # Reject relative script paths that are not safe to embed in shell snippets.
  validateSkillScriptRelativePaths =
    paths:
    let
      invalidPaths = lib.filter (path: builtins.match portableSkillScriptPathPattern path == null) paths;
    in
    if invalidPaths == [ ] then
      paths
    else
      throw "Unsafe standalone skill script relative path(s): ${lib.concatStringsSep ", " invalidPaths}. Paths must contain only ASCII letters, digits, '.', '_', '-', and '/'.";
}
