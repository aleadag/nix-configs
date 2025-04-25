{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./httpie.nix
    ./nix.nix
  ];

  options.home-manager.dev.enable = lib.mkEnableOption "dev config" // {
    default = true;
  };

  config = lib.mkIf config.home-manager.dev.enable {
    home.packages = with pkgs; [
      bash-language-server
      expect
      marksman
      shellcheck
    ];

    # Use direnv to manage development environments
    programs = {
      direnv = {
        enable = true;
        enableZshIntegration = false;
      };

      tealdeer = {
        enable = true;
        settings = {
          display = {
            compact = false;
            use_pager = true;
          };
          updates = {
            auto_update = false;
          };
        };
      };

      zsh.initContent =
        # manually creating integrations since this is faster than calling
        # the `direnv hook zsh` itself during startup
        # bash
        ''
          source ${
            pkgs.runCommand "direnv-hook-zsh" { buildInputs = [ config.programs.direnv.package ]; } ''
              direnv hook zsh > $out
            ''
          }
        '';
    };
  };
}
