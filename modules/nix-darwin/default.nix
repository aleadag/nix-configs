{ flake, ... }:

{
  imports = [
    flake.inputs.stylix.darwinModules.stylix
    flake.outputs.internal.sharedModules.default
    ./cli.nix
    ./home.nix
    ./homebrew.nix
    ./nix
    ./preferences.nix
    ./system.nix

    ./borders
    ./yabai
    ./sketchybar
    ./skhd
    ./kanata
  ];
}
