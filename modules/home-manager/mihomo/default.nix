{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    getExe
    ;

  cfg = config.home-manager.mihomo;

  mkUnit = package: {
    Unit.Description = "mihomo";

    Install.WantedBy = [ "default.target" ];

    Service = {
      ExecStart = "${getExe package}";
      Restart = "on-abort";
    };
  };

  mkAgent = package: {
    enable = true;
    config = {
      ProgramArguments = [ "${getExe package}" ];
    };
  };

  mkService = if pkgs.stdenv.isLinux then mkUnit else mkAgent;

  services = {
    mihomo = mkService pkgs.mihomo;
  };
in
{
  options.home-manager.mihomo = {
    enable = lib.mkEnableOption "mihomo service" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf pkgs.stdenv.isLinux { systemd.user.services = services; })
      (mkIf pkgs.stdenv.isDarwin { launchd.agents = services; })
      {
        sops.secrets.mihomo = {
          sopsFile = ../../../secrets/airport.yaml;
          format = "yaml";
          key = "";
          path = "${config.home.homeDirectory}/.config/mihomo/config.yaml";
        };
      }
    ]
  );
}
