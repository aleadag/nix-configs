{
  config,
  flake,
  lib,
  ...
}:

{
  imports = [
    flake.inputs.catppuccin.homeModules.default
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
    catppuccin = {
      inherit (config.theme) flavor;
      enable = true;
      fcitx5.enable = false;
    };

    home = {
      username = lib.mkOptionDefault "awang";
      homeDirectory = lib.mkOptionDefault "/home/awang";
    };
  };
}
