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
        nix-direnv.enable = true;
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
    };
  };
}
