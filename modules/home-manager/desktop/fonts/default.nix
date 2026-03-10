{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.fonts;
in
{
  options.home-manager.desktop.fonts = {
    enable = lib.mkEnableOption "font config" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Noto fonts is a good fallback font
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "Noto Sans Mono"
          "Noto Sans Mono CJK SC"
        ];
        serif = [
          "Noto Serif"
          "Noto Serif CJK SC"
        ];
        sansSerif = [
          "Noto Sans"
          "Noto Sans CJK SC"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
