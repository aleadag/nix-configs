{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.cc-connect;
  configPath = "${config.home.homeDirectory}/.cc-connect/config.toml";
  configFile = (pkgs.formats.toml { }).generate "cc-connect-config" cfg.settings;
in
{
  options.home-manager.cc-connect = {
    enable = lib.mkEnableOption "cc-connect";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cc-connect;
      description = "cc-connect package to install and run.";
    };

    codexPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llm-agents.codex;
      description = "Codex package made available to cc-connect.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "cc-connect configuration written as TOML.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Environment files loaded by the cc-connect user service.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "home-manager.cc-connect currently supports Linux user services only.";
      }
    ];

    home = {
      packages = [
        cfg.package
        cfg.codexPackage
      ];

      file.".cc-connect/config.toml" = {
        source = configFile;
        force = true;
      };
    };

    systemd.user.services.cc-connect = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "cc-connect";
        X-Restart-Triggers = [ configFile ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        Environment = [
          "PATH=${lib.makeBinPath [ cfg.codexPackage ]}:${config.home.profileDirectory}/bin"
        ];
        ExecStart = "${lib.getExe cfg.package} -config ${configPath}";
        Restart = "on-failure";
      }
      // lib.optionalAttrs (cfg.environmentFiles != [ ]) { EnvironmentFile = cfg.environmentFiles; };
    };
  };
}
