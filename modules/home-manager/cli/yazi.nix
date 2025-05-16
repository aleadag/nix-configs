{
  config,
  lib,
  ...
}:

let
  enableIcons = config.home-manager.cli.icons.enable;
  cfg = config.home-manager.cli.yazi;
in
{
  options.home-manager.cli.yazi = {
    enable = lib.mkEnableOption "yazi config" // {
      default = config.home-manager.cli.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals enableIcons [
      config.theme.fonts.symbols.package
    ];

    programs.yazi = {
      enable = true;
    };
  };
}
