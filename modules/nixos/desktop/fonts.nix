{
  config,
  lib,
  ...
}:

{
  options.nixos.desktop.fonts.enable = lib.mkEnableOption "fonts config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.fonts.enable {
    nixos.home.extraModules = {
      fonts.fontconfig = with config.fonts.fontconfig; {
        enable = true;
        antialiasing = antialias;
        hinting = lib.mkIf hinting.enable hinting.style;
        subpixelRendering = subpixel.rgba;
      };
    };

    fonts = {
      fontDir.enable = true;

      fontconfig = {
        # fix emojis in Firefox
        useEmbeddedBitmaps = true;
        defaultFonts = lib.mkIf (config ? stylix.fonts.cjk && config.stylix.fonts.cjk.enable) {
          monospace = lib.mkAfter [ config.stylix.fonts.cjk.monospace.name ];
          serif = lib.mkAfter [ config.stylix.fonts.cjk.serif.name ];
          sansSerif = lib.mkAfter [ config.stylix.fonts.cjk.sansSerif.name ];
        };
      };
    };
  };
}
