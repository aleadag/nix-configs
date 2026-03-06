{
  flake,
  lib,
  ...
}:

{
  imports = [
    flake.inputs.nix-openclaw.homeManagerModules.openclaw
    flake.inputs.stylix.homeModules.stylix
    flake.outputs.internal.sharedModules.default
    ./cli
    ./crostini.nix
    ./darwin
    ./desktop
    ./dev
    ./editor
    ./gui
    ./kanata
    ./meta
    ./mihomo
    ./nix
    ./openclaw
    ./sops.nix
    ./syncthing.nix
    ./window-manager
  ];

  options.home-manager = {
    hostName = lib.mkOption {
      description = "The hostname of the machine.";
      type = lib.types.str;
      default = "generic";
    };
  };

  config = {
    home = {
      username = lib.mkOptionDefault "awang";
      homeDirectory = lib.mkOptionDefault "/home/awang";
    };
  };
}
