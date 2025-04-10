{ lib, ... }:

{
  imports = [
    ../shared
    ./cli
    ./crostini.nix
    ./darwin
    ./desktop
    ./dev
    ./editor
    ./gui
    ./meta
    ./nix
  ];

  home = {
    username = lib.mkDefault "awang";
    homeDirectory = lib.mkDefault "/home/awang";
    stateVersion = lib.mkDefault "25.05";
  };
}
