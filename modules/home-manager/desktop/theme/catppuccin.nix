{ flake, config, ... }:
let
  cfg = config.home-manager.desktop.theme;
in
{
  imports = [
    flake.inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    inherit (cfg) flavor;
    enable = true;
    cache.enable = true;
    # Workaround: https://github.com/catppuccin/nix/issues/552
    mako.enable = false;
  };
}
