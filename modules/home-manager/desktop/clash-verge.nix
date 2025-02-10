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

  config = lib.mkIf config.home-manager.desktop.clash-verge.enable {
    home.packages = with pkgs; [ clash-verge-rev ];

    systemd.user.services.clash-verge = {
      Unit = {
        Description = "clash verge rev";
      };

      Install.WantedBy = [ "multi-user.target" ];

      Service = {
        ExecStart = "${pkgs.clash-verge-rev}/bin/clash-verge-service";
      };
    };
  };
}
