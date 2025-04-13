{
  lib,
  ...
}:
{
  imports = [
    ./config.nix
    ./sketchybar
    ./skhd
  ];

  options.nix-darwin.yabai.enable = lib.mkEnableOption "yabai config" // {
    default = true;
  };
}
