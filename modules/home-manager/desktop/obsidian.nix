{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.desktop.obsidian.enable = lib.mkEnableOption "Obsidian config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.obsidian.enable {
    programs.obsidian =
      let
        vault-nickname = pkgs.fetchzip {
          url = "https://github.com/rscopic/obsidian-vault-nickname/releases/download/1.1.8/obsidian-vault-nickname-v1.1.8.zip";
          name = "vault-nickname";
          stripRoot = false;
          hash = "sha256-qET6q2u49gVkFL2fmAasXAue7qRHQVq0U5z6CW6ZpvE=";
        };
      in
      {
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
          lucid = {
            target = "hacking/tiwater/lucid/docs";
            settings.communityPlugins = [
              {
                pkg = vault-nickname;
              }
            ];
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
