{
  lib,
  options,
  pkgs,
  ...
}:
{
  config = {
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-frappe.yaml";
      polarity = "dark";

      # Wallpaper configuration
      image = lib.mkDefault "${pkgs.pop-wallpapers}/share/backgrounds/pop/ahmadreza-sajadi-10140-edit.jpg";

      # Image scaling mode: "fill" (default, crops), "fit" (no crop, may have bars), "center", "tile", "stretch"
      imageScalingMode = "fill";

      # Font configuration
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.hack;
          name = "Hack Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.noto-fonts-cjk-sans;
          name = "Noto Sans CJK SC";
        };
        serif = {
          package = pkgs.noto-fonts-cjk-serif;
          name = "Noto Serif CJK SC";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };
    }
    // lib.optionalAttrs (options ? stylix.cursor) {
      cursor = {
        package = pkgs.catppuccin-cursors.frappeBlue;
        name = "catppuccin-frappe-blue-cursors";
        size = 24;
      };
    }
    // lib.optionalAttrs (options ? stylix.icons) {
      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        light = "Papirus-Light";
      };
    }
    // lib.optionalAttrs (options ? stylix.homeManagerIntegration) {
      # NixOS-specific: disable home-manager integration
      homeManagerIntegration.autoImport = false;
    };
  }
  // lib.optionalAttrs (options ? gtk) {
    # Required so home-manager writes gtk-icon-theme-name to settings.ini and
    # installs the icon theme package; stylix.icons only sets gtk.iconTheme.
    gtk.enable = true;
  };
}
