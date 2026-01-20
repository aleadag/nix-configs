{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.dev.codex;
in
{
  options.home-manager.dev.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };

    home.file =
      let
        commands = builtins.readDir ./commands;
        commandFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) commands;
        # Map each command to .codex/skills/<name>/SKILL.md
        skillFiles = lib.mapAttrs' (
          name: _:
          let
            skillName = lib.removeSuffix ".md" name;
          in
          lib.nameValuePair ".codex/skills/${skillName}/SKILL.md" {
            text = builtins.readFile (./commands + "/${name}");
          }
        ) commandFiles;
      in
      skillFiles;
  };
}
