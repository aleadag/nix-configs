{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli.bulletty;
in
{
  options.home-manager.cli.bulletty.enable = lib.mkEnableOption "bulletty config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.bulletty ];
      file.".config/bulletty/config.toml".source = (pkgs.formats.toml { }).generate "bulletty" {
        datapath = "${config.home.homeDirectory}/Sync/bulletty";
      };
    };
  };
}
