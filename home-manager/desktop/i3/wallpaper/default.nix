{ config, lib, pkgs, ... }:

{
  options.home-manager.desktop.i3.wallpaper.enable = lib.mkEnableOption "wallpaper config" // {
    default = config.home-manager.desktop.i3.enable;
  };

  config = lib.mkIf config.home-manager.desktop.i3.wallpaper.enable (
    let
      fetch-bing-wallpaper = pkgs.callPackage ./fetch-bing-wallpaper.nix { inherit (config.home-manager.desktop.theme.wallpaper) cachePath; };
    in
    {
      systemd.user = {
        services = {
          feh-bing = {
            Unit = {
              Description = "Downloads BING image and sets a wallpaper";
              PartOf = "graphical-session.target";
            };

            Service = { ExecStart = "${fetch-bing-wallpaper}/bin/fetch-bing-wp"; };
          };
        };

        timers = {
          feh-bing = {
            Unit = { Description = "Run feh-bing service repeatly and on boot"; };

            Timer = {
              OnBootSec = "30min";
              OnUnitActiveSec = "3h";
            };
          };
        };
      };
    }
  );
}
