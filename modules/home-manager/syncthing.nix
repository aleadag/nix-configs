{
  config,
  flake,
  lib,
  ...
}:
let
  cfg = config.home-manager.syncthing;
in
{
  options.home-manager.syncthing.enable = lib.mkEnableOption "Syncthing config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.syncthing.enable = true;
  };
}
