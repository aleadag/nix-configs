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
  mihomoTemplate = builtins.readFile (
    pkgs.replaceVars ./config.yaml {
      inherit (config.sops.placeholder) airport1;
      inherit (config.sops.placeholder) airport2;
      inherit (config.sops.placeholder) mihomo_secret;
    }
  );

  mkUnit = package: {
    Unit.Description = "mihomo";

    Install.WantedBy = [ "default.target" ];

    Service = {
      ExecStart = "${getExe package} -f ${config.sops.templates."mihomo.yaml".path}";
      Restart = "on-failure";
    };
  };

  mkAgent = package: {
    enable = true;
    config = {
      ProgramArguments = [
        (getExe package)
        "-f"
        config.sops.templates."mihomo.yaml".path
      ];
      KeepAlive = true;
      RunAtLoad = true;
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
      (mkIf pkgs.stdenv.isLinux {
        systemd.user.services = services;
        xdg.desktopEntries.mihomo-web-ui = {
          name = "Mihomo Web UI";
          genericName = "Web UI";
          exec = "open-browser http://127.0.0.1:9090/ui";
          terminal = false;
          categories = [
            "Application"
            "Network"
          ];
          mimeType = [
            "text/html"
          ];
        };
      })
      (mkIf pkgs.stdenv.isDarwin { launchd.agents = services; })
      {
        # 注意规则在满足自己需求情况下，尽量做到精简，不要过度复杂，以免影响性能。
        # https://github.com/qichiyuhub/rule/blob/main/config/mihomo/config.yaml
        sops = {
          secrets = {
            airport1 = { };
            airport2 = { };
            mihomo_secret = { };
          };
          templates."mihomo.yaml".content = mihomoTemplate;
        };
      }
    ]
  );
}
