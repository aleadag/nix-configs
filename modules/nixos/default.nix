{ flake, ... }:

{
  imports = [
    flake.inputs.catppuccin.nixosModules.default
    flake.outputs.internal.sharedModules.default
    ./desktop
    ./games
    ./home.nix
    ./laptop
    ./nix
    ./server
    ./system
  ];
}
