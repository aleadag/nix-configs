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
    ./fonts
    ./gtk.nix
    ./qt.nix
    ./catppuccin.nix
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
      path = lib.mkOption {
        type = lib.types.path;
        description = "Wallpaper path.";
        default = "${pkgs.cosmic-wallpapers}/share/backgrounds/cosmic/A_stormy_stellar_nursery_esa_379309.jpg";
      };
      scale = lib.mkOption {
        type = lib.types.enum [
          "tile"
          "center"
          "fill"
          "scale"
        ];
        default = "fill";
        description = "Wallpaper scaling.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      pointerCursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 32;
        x11.enable = true;
        gtk.enable = true;
      };
    };
  };
}
