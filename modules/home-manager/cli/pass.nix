{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.cli.pass;
in
{

  options.home-manager.cli.pass = {
    enable = lib.mkEnableOption "password-store config" // {
      default = config.home-manager.cli.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      password-store = {
        enable = true;
        # package = pkgs.pass.withExtensions (exts: [ exts.pass-import ]);
        settings = {
          PASSWORD_STORE_DIR = "$HOME/sync/pass";
          PASSWORD_STORE_CLIP_TIME = "60";
        };
      };

      zsh.initContent = # zsh
        ''
          _fzf_complete_pass() {
            _fzf_complete +m -- "$@" < <(
              local prefix
              prefix="''${PASSWORD_STORE_DIR:-$HOME/.password-store}"
              command find -L "$prefix" \
                -name "*.gpg" -type f | \
                sed -e "s#''${prefix}/\{0,1\}##" -e 's#\.gpg##' -e 's#\\#\\\\#' | sort
            )
          }
        '';

      gpg = {
        enable = true;
        # settings = ;
      };

      browserpass = {
        enable = cfg.enable;
        browsers = [ "firefox" ];
      };
    };

    services.gpg-agent.enable = true;
  };
}
