{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.desktop.wps;
in
{
  options.home-manager.desktop.wps = {
    enable = lib.mkEnableOption "WPS Office config" // {
      default = config.home-manager.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.nur.repos.fym998.wpsoffice-cn-fcitx ];
  };
}
