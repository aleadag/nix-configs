{
  config,
  lib,
  ...
}:

{
  options.home-manager.desktop.obsidian.enable = lib.mkEnableOption "Obsidian config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.obsidian.enable {
    programs.obsidian = {
      enable = true;
      cli.enable = true;
      defaultSettings = {
        app = {
          safeMode = false;
          vimMode = true;
          showLineNumber = true;
        };
      };
      vaults = {
        awang.target = "sync/AWANG";
        lucid.target = "hacking/tiwater/lucid/lucid-docs";
      };
    };

    stylix.targets.obsidian = {
      vaultNames = [
        "awang"
        "lucid"
      ];
    };
  };
}
