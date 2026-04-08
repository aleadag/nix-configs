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
      vaults =
        let
          corePlugins = [
            "backlink"
            "bookmarks"
            "command-palette"
            "daily-notes"
            "editor-status"
            "file-explorer"
            "file-recovery"
            "global-search"
            "graph"
            "note-composer"
            "outgoing-link"
            "outline"
            "page-preview"
            "switcher"
            "tag-pane"
            "templates"
            "word-count"
            "zk-prefixer"
          ];
        in
        {
          awang = {
            target = "sync/AWANG";
            settings.corePlugins = [
              {
                name = "daily-notes";
                enable = true;
                settings = {
                  folder = "02. Journaling";
                };
              }
            ]
            ++ corePlugins;
          };
          lucid = {
            target = "hacking/tiwater/lucid/lucid-docs";
            settings.corePlugins = [
              "bases"
            ]
            ++ corePlugins;
          };
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
