{ config, flake, ... }:

{
  imports = [
    flake.outputs.internal.sharedModules.default
    ./cli.nix
    ./home.nix
    ./homebrew.nix
    ./nix
    ./system.nix
    ./yabai
  ];

  system.primaryUser = config.meta.username;
}
