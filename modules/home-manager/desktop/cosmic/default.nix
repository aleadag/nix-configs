{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.cosmic;
in
{
  options.home-manager.desktop.cosmic = {
    enable = lib.mkEnableOption "COSMIC desktop environment" // {
      default = config.home-manager.window-manager.wayland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable cosmic-manager for declarative COSMIC configuration
    wayland.desktopManager.cosmic.enable = true;

    programs = {
      cosmic-ext-ctl.enable = true;
      cosmic-ext-tweaks.enable = true;
    };
  };
}
