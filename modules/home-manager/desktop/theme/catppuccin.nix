{ flake, config, ... }:
let
  cfg = config.home-manager.desktop.theme;
in
{
  imports = [
    flake.inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin.flavor = cfg.flavor;
  catppuccin.enable = true;
}
