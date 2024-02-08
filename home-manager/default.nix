{ pkgs, lib, osConfig, ... }:

{
  imports = [
    # ./cli
    # ./crostini.nix
    # ./darwin
    # ./desktop
    # ./editor
    ./meta
  ];

  # Inherit config from NixOS or homeConfigurations
  inherit (osConfig) device mainUser;

  # Assume that this is a non-NixOS system
  targets.genericLinux.enable = lib.mkIf pkgs.stdenv.isLinux (lib.mkDefault true);
}
