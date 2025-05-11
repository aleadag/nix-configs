{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.home-manager.desktop.nyxt;
in
{
  options.home-manager.desktop.nyxt.enable = lib.mkEnableOption "Nyxt config" // {
    # not stable for now
    default = false;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ nyxt ];

    xdg.configFile."nyxt" = {
      source = ./config;
      recursive = true;
    };
  };
}
