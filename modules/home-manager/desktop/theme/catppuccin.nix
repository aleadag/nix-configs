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
    # MUST disable this! otherwise, it will overwrite existing nix/substituters!
    cache.enable = false;
    # Workaround: https://github.com/catppuccin/nix/issues/552
    mako.enable = false;
    fcitx5.enable = false;
  };
}
