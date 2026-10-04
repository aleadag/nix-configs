{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.collie;
  package = pkgs.llm-agents.collie.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      cp -r web/src $out/lib/collie/web/src
    '';
  });
in
{
  options.home-manager.dev.coding-agents.collie = {
    enable = lib.mkEnableOption "Collie";
    publicHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Hostnames allowed to reach Collie through a reverse proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];

    systemd.user.services.collie = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit.Description = "Collie";
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = lib.getExe package;
        Environment = [
          "COLLIE_HOST=127.0.0.1"
          "COLLIE_TRUSTED_USER=${config.meta.email}"
          "COLLIE_PUBLIC_HOSTS=${lib.concatStringsSep "," cfg.publicHosts}"
        ];
        Restart = "on-failure";
      };
    };

    launchd.agents.collie = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe package) ];
        EnvironmentVariables = {
          COLLIE_HOST = "127.0.0.1";
          COLLIE_TRUSTED_USER = config.meta.email;
          COLLIE_PUBLIC_HOSTS = lib.concatStringsSep "," cfg.publicHosts;
        };
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
