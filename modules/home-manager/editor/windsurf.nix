{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.home-manager.editor.windsurf.enable = lib.mkEnableOption "Enable WindSurf" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf config.home-manager.editor.windsurf.enable (
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      enableXdgConfig = !isDarwin || config.xdg.enable;
      configDir =
        {
          "vscode" = "Code";
          "vscode-insiders" = "Code - Insiders";
          "vscodium" = "VSCodium";
          "openvscode-server" = "OpenVSCode Server";
          "windsurf" = "Windsurf";
          "cursor" = "Cursor";
        }
        .${config.programs.vscode.package.pname};
    in
    {
      programs.vscode = {
        enable = true;
        package = pkgs.windsurf;

        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            # General
            vscodevim.vim
            mkhl.direnv
            # Icons
            catppuccin.catppuccin-vsc-icons
          ];

          userSettings = {
            "windsurf.autocompleteSpeed" = "fast";
            "git.openRepositoryInParentFolders" = "prompt";
          };
        };
      };

      mutableConfig.files = {
        "${
          if enableXdgConfig then config.xdg.configHome else "Library/Application Support"
        }/${configDir}/User/settings.json" =
          config.programs.vscode.profiles.default.userSettings;
      };
    }
  );
}
