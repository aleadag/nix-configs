{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.wechat;
in
{
  options.home-manager.desktop.wechat = {
    enable = lib.mkEnableOption "wechat-uos" // {
      default = config.home-manager.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wechat-uos ];
  };
}
