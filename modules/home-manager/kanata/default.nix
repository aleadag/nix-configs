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

  cfg = config.home-manager.kanata;

  # https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md
  # for arch linux, one more step:
  # https://github.com/chrippa/ds4drv/issues/93#issuecomment-265300511
  mkUnit = package: {
    Unit.Description = "kanata";

    Install.WantedBy = [ "default.target" ];

    Service = {
      ExecStart = "${getExe package} --cfg ${config.xdg.configHome}/kanata/kanata.kbd";
      Restart = "on-failure";
    };
  };

  mkAgent = package: {
    enable = true;
    config = {
      ProgramArguments = [
        "sudo"
        (getExe package)
        "--cfg"
        "${config.xdg.configHome}/kanata/kanata.kbd"
      ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  mkService = if pkgs.stdenv.isLinux then mkUnit else mkAgent;

  services = {
    kanata = mkService pkgs.kanata;
  };
in
{
  options.home-manager.kanata = {
    enable = lib.mkEnableOption "kanata service" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf pkgs.stdenv.isLinux {
        systemd.user.services = services;
      })
      (mkIf pkgs.stdenv.isDarwin { launchd.agents = services; })
      {
        xdg.configFile."kanata/kanata.kbd".text = # scheme
          ''
            ;; defsrc is still necessary
            (defcfg
              process-unmapped-keys yes
            )

            (defsrc
              caps a s d f j k l ;
            )
            (defvar
              tap-time 150
              hold-time 200
            )

            (defalias
              escctrl (tap-hold 100 100 esc lctl)
              a (multi f24 (tap-hold $tap-time $hold-time a lmet))
              s (multi f24 (tap-hold $tap-time $hold-time s lalt))
              d (multi f24 (tap-hold $tap-time $hold-time d lsft))
              f (multi f24 (tap-hold $tap-time $hold-time f lctl))
              j (multi f24 (tap-hold $tap-time $hold-time j rctl))
              k (multi f24 (tap-hold $tap-time $hold-time k rsft))
              l (multi f24 (tap-hold $tap-time $hold-time l ralt))
              ; (multi f24 (tap-hold $tap-time $hold-time ; rmet))
            )

            (deflayer base
              @escctrl @a @s @d @f @j @k @l @;
            )
          '';
      }
    ]
  );
}
