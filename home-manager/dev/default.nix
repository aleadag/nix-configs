{ config, pkgs, lib, ... }:

{
  imports = [
    ./httpie.nix
  ];

  options.home-manager.dev.enable = lib.mkEnableOption "dev config" // {
    default = true;
  };

  config = lib.mkIf config.home-manager.dev.enable {
    home.packages = with pkgs; [
      expect
      marksman
      nodePackages.bash-language-server
      shellcheck
    ];

    # Use direnv to manage development environments
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      # optional for nix flakes support in home-manager 21.11, not required in home-manager unstable or 22.05
      # nix-direnv.enableFlakes = true;
    };
  };
}
