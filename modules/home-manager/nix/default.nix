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
        nix-proxy-manager
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
      settings = flake.outputs.internal.configs.nix;
      extraOptions = ''
        netrc-file = ${config.sops.secrets.netrc.path}
        !include nix.local.conf
      '';
    };

    # https://dl.thalheim.io/
    sops = {
      secrets =
        let
          sopsFile = ../../../secrets/attic.yaml;
        in
        {
          attic = {
            inherit sopsFile;
            path = "${config.home.homeDirectory}/.config/attic/config.toml";
          };
          netrc = {
            inherit sopsFile;
          };
        };
    };

    # Config for ad-hoc nix commands invocation
    xdg.configFile."nixpkgs/config.nix".text =
      lib.generators.toPretty { }
        flake.outputs.internal.configs.nixpkgs;
  };
}
