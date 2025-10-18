{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.cli.yazi;
in
{
  options.home-manager.cli.yazi = {
    enable = lib.mkEnableOption "yazi config" // {
      default = config.home-manager.cli.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
    };
  };
}
