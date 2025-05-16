{ pkgs, lib, ... }:

{
  imports = [
    ./fonts.nix
  ];

  options.theme = {
    flavor = lib.mkOption {
      type = lib.types.str;
      description = "Catppuccin flavor";
      default = "frappe";
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
}
