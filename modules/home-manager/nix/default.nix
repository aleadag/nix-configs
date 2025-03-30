{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.nix;
in
{
  options.home-manager.nix.enable = lib.mkEnableOption "Nix config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home = {
      # Add some Nix related packages
      packages = with pkgs; [
        nix-cleanup
        nix-whereis
        # Multi-tenant Nix Binary Cache
        attic-client
      ];
      # For standalone HM usage to make e.g.: nix-shell work as expected
      sessionVariables.NIX_PATH = "nixpkgs=${flake.inputs.nixpkgs}";
    };

    # To make cachix work you need add the current user as a trusted-user on Nix
    # sudo echo "trusted-users = $(whoami)" >> /etc/nix/nix.conf
    # Another option is to add a group by prefixing it by @, e.g.:
    # sudo echo "trusted-users = @wheel" >> /etc/nix/nix.conf
    nix = {
      package = lib.mkDefault pkgs.nix;
      settings = lib.mkMerge [
        (import ../../shared/config/nix.nix)
        (import ../../shared/config/substituters.nix)
      ];
      extraOptions = ''
        !include nix.local.conf
      '';
    };

    # Config for ad-hoc nix commands invocation
    xdg.configFile."nixpkgs/config.nix".source = ../../shared/config/nixpkgs.nix;
  };
}
