{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  fontType = lib.types.submodule {
    options = {
      package = lib.mkOption {
        type = lib.types.package;
        description = "Package providing the CJK font.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "Font family name.";
      };
    };
  };
  cjkPackages = lib.unique [
    config.stylix.fonts.cjk.sansSerif.package
    config.stylix.fonts.cjk.serif.package
    config.stylix.fonts.cjk.monospace.package
  ];
in
{
  options.stylix.fonts.cjk = {
    enable = lib.mkEnableOption "CJK fallback font support" // {
      default = config.stylix.enable;
    };
    sansSerif = lib.mkOption {
      type = fontType;
      default = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK SC";
      };
      description = "CJK sans-serif font.";
    };
    serif = lib.mkOption {
      type = fontType;
      default = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK SC";
      };
      description = "CJK serif font.";
    };
    monospace = lib.mkOption {
      type = fontType;
      default = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans Mono CJK SC";
      };
      description = "CJK monospace font.";
    };
  };

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
          package = pkgs.noto-fonts;
          name = "Noto Sans";
        };
        serif = {
          package = pkgs.noto-fonts;
          name = "Noto Serif";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };
    }
    // lib.optionalAttrs (options ? stylix.cursor) {
      cursor = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        package = pkgs.catppuccin-cursors.frappeDark;
        name = "catppuccin-frappe-dark-cursors";
        size = 24;
      };
    }
    // lib.optionalAttrs (options ? stylix.icons) {
      icons = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        # papirus-icon-theme propagates breeze-icons, so Papirus-Dark's
        # `Inherits=breeze-dark` chain resolves (fcitx5 tray icon, etc.).
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
  // lib.optionalAttrs (options ? gtk.enable) {
    # Required so home-manager writes gtk-icon-theme-name to settings.ini and
    # installs the icon theme package; stylix.icons only sets gtk.iconTheme.
    gtk.enable = true;
  }
  // lib.optionalAttrs (options ? dconf.enable) {
    # gtk sets dconf settings (org/gnome/desktop/interface) which trigger dconf
    # activation. On standalone Linux (genericLinux) the dconf D-Bus service is
    # not available, so activation fails; disable dconf there.
    dconf.enable = lib.mkIf config.targets.genericLinux.enable false;
  }
  // lib.optionalAttrs (options ? home.packages) {
    home.packages = lib.mkIf (config.stylix.enable && config.stylix.fonts.cjk.enable) cjkPackages;
  }
  // lib.optionalAttrs (options ? fonts.packages) {
    fonts.packages = lib.mkIf (config.stylix.enable && config.stylix.fonts.cjk.enable) cjkPackages;
  };
}
