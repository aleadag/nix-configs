{ flake, ... }:

{
  imports = [
    flake.inputs.stylix.nixosModules.stylix
    flake.outputs.internal.sharedModules.default
    ./desktop
    ./dev
    ./games
    ./home.nix
    ./laptop
    ./nix
    ./server
    ./system
    ./window-manager
  ];
}
