{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.home-manager.window-manager.theme.gtk.enable = lib.mkEnableOption "GTK theme config" // {
    default = config.home-manager.window-manager.theme.enable;
  };

  config = lib.mkIf config.home-manager.window-manager.theme.gtk.enable {
    home = {
      packages = with pkgs; [
        gnome-themes-extra
        hicolor-icon-theme
      ];
    };

    gtk = {
      enable = true;
      font = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
    };

    catppuccin.gtk = {
      enable = true;
      icon.enable = true;
    };

    services.xsettingsd = {
      enable = true;
      settings = with config; {
        # When running, most GNOME/GTK+ applications prefer those settings
        # instead of *.ini files
        "Net/IconThemeName" = gtk.iconTheme.name;
        "Net/ThemeName" = gtk.theme.name;
        "Gtk/CursorThemeName" = xsession.pointerCursor.name;
      };
    };
  };
}
