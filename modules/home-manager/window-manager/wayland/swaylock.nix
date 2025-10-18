{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.window-manager.wayland.swaylock;
  kbLayouts = lib.splitString "," (config.home.keyboard.layout or "");
in
{
  options.home-manager.window-manager.wayland.swaylock.enable =
    lib.mkEnableOption "swaylock config"
    // {
      default = config.home-manager.window-manager.wayland.enable;
    };

  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        indicator-caps-lock = true;
        show-keyboard-layout = true;

        # when we have 0 keyboard layouts, it probably means we are using HM
        # standalone, so we can't trust the keyboard module
        hide-keyboard-layout = lib.mkIf ((builtins.length kbLayouts) == 1) true;
        ignore-empty-password = true;

        indicator-radius = 80;
        indicator-thickness = 10;
      };
    };
  };
}
