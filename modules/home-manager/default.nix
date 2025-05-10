{ flake, lib, ... }:

{
  imports = [
    flake.outputs.internal.sharedModules.default
    ./cli
    ./crostini.nix
    ./darwin
    ./desktop
    ./dev
    ./editor
    ./gui
    ./meta
    ./mihomo
    ./nix
    ./sops.nix
    ./syncthing.nix
  ];

  home = {
    username = lib.mkOptionDefault "awang";
    homeDirectory = lib.mkOptionDefault "/home/awang";
    stateVersion = lib.mkOptionDefault "25.05";
  };
}
