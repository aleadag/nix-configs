{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.desktop.nixgl;
in
{
  options.home-manager.desktop.nixgl = {
    enable = lib.mkEnableOption "nixGL config" // {
      default = config.targets.genericLinux.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    targets.genericLinux.nixGL = {
      inherit (flake.inputs.nixgl) packages;
    };

    programs = with config.lib.nixGL; {
      firefox.package = lib.mkForce (wrap pkgs.firefox);
      mpv.package = lib.mkForce (wrap pkgs.mpv);
    };

    wayland.windowManager.sway.package = lib.mkForce (config.lib.nixGL.wrap pkgs.sway);
    home-manager.window-manager.wayland.niri.package = lib.mkForce (config.lib.nixGL.wrap pkgs.niri);
  };
}
