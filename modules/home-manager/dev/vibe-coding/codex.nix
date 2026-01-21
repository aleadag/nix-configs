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
      settings = {
        analytics.enabled = false;
        check_for_update_on_startup = false;
      };
      custom-instructions = builtins.readFile ./CONTEXT.md;
      skills =
        let
          commands = builtins.readDir ./commands;
          commandFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) commands;
        in
        lib.mapAttrs' (
          name: _:
          let
            skillName = lib.removeSuffix ".md" name;
          in
          lib.nameValuePair skillName (builtins.readFile (./commands + "/${name}"))
        ) commandFiles;
    };
  };
}
