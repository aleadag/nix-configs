{ flake, ... }:

{
  imports = [
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
