{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.desktop.clash-verge.enable = lib.mkEnableOption "clash verge rev" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.clash-verge.enable (
    let
      clash-verge-wrapped = with config.lib.nixGL; (wrap pkgs.clash-verge-rev);
    in
    {
      systemd.user.services.clash-verge-service = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          Description = "clash verge rev";
        };

        Service = {
          inherit (config.home-manager.desktop.systemd.service) RestartSec RestartSteps RestartMaxDelaySec;
          ExecStart = "${clash-verge-wrapped}/bin/clash-verge-service";
        };
      };

      systemd.user.services.clash-verge = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          Description = "clash verge rev";
          Requires = "clash-verge-service.service";
          After = [ "clash-verge-service.service" ];
        };

        Service = {
          inherit (config.home-manager.desktop.systemd.service) RestartSec RestartSteps RestartMaxDelaySec;
          ExecStart = "${clash-verge-wrapped}/bin/clash-verge";
        };
      };
    }
  );
}
