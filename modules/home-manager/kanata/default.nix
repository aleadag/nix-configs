{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.home-manager.kanata;

in
{
  options.home-manager.kanata = {
    enable = lib.mkEnableOption "kanata service" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md
    # for arch linux, one more step:
    # https://github.com/chrippa/ds4drv/issues/93#issuecomment-265300511
    systemd.user.services.kanata = {
      Unit.Description = "kanata";
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = "${getExe pkgs.kanata} --cfg ${config.xdg.configHome}/kanata/kanata.kbd";
        Restart = "on-failure";
      };
    };

    xdg.configFile."kanata/kanata.kbd".source = ../../../configs/kanata.kbd;
  };
}
