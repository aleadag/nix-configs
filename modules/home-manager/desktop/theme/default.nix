{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.theme;
in
{
  imports = [
    ./fonts.nix
    ./gtk.nix
    ./qt.nix
  ];

  options.home-manager.desktop.theme = {
    enable = lib.mkEnableOption "theme config" // {
      default = config.home-manager.desktop.enable;
    };

    flavor = lib.mkOption {
      type = lib.types.str;
      description = "Catppuccin flavor";
      default = "frappe";
    };

    colors = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = "Catppuccin colors";
      default = (lib.importJSON ./colors.json)."${config.home-manager.desktop.theme.flavor}";
    };

    wallpaper = {
      cachePath = lib.mkOption {
        type = lib.types.path;
        description = "Wallpaper cache path";
        default = "${config.home.homeDirectory}/Pictures/Bing/";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      pointerCursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 24;
        x11.enable = true;
        gtk.enable = true;
      };
    };
  };
}
