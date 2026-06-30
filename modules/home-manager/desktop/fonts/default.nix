{
  config,
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
    fonts.fontconfig.enable = true;
  };
}
