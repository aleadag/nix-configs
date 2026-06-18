{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli.bulletty;
  configPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/bulletty/config.toml"
    else
      ".config/bulletty/config.toml";
in
{
  options.home-manager.cli.bulletty.enable = lib.mkEnableOption "bulletty config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.bulletty ];
      file.${configPath}.source = (pkgs.formats.toml { }).generate "bulletty" {
        datapath = "${config.home.homeDirectory}/Sync/bulletty";
      };
    };
  };
}
