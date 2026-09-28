{ config, lib, ... }:

{
  options.home-manager.window-manager.gammastep = {
    enable = lib.mkEnableOption "gammastep config" // {
      default = config.home-manager.window-manager.enable;
    };
    tray.enable = lib.mkEnableOption "gammastep tray indicator" // {
      default = true;
    };
  };

  config = lib.mkIf config.home-manager.window-manager.gammastep.enable {
    services.gammastep = {
      enable = config.device.type != "vm";
      tray = config.home-manager.window-manager.gammastep.tray.enable;
      dawnTime = "6:30-7:30";
      duskTime = "18:30-19:30";
      temperature = {
        day = 5700;
        night = 3700;
      };
      settings = {
        general = {
          gamma = 0.8;
          fade = 1;
        };
      };
    };
  };
}
