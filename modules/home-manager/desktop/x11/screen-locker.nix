{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.desktop.x11.screen-locker.enable =
    lib.mkEnableOption "screen-locker config"
    // {
      default = config.home-manager.desktop.x11.enable;
    };

  config = lib.mkIf config.home-manager.desktop.x11.screen-locker.enable {
    services.screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "slock"; # use self installed slock because of permission issue
      # Use xss-lock instead
      xautolock.enable = false;
      xss-lock = {
        extraOptions =
          let
            notify = pkgs.writeShellScript "notify" ''
              ${lib.getExe' pkgs.dunst "dunstify"} -t 30000 "30 seconds to lock"
            '';
          in
          [
            "--notifier ${notify}"
            "--transfer-sleep-lock"
            "--session $XDG_SESSION_ID"
          ];
        screensaverCycle = 600;
      };
    };
  };
}
