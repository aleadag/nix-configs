{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.cli.yazi;
in
{
  options.home-manager.cli.yazi = {
    enable = lib.mkEnableOption "yazi config" // {
      default = config.home-manager.cli.enable;
    };
    # Do not forget to set 'Hack Nerd Mono Font' as the terminal font
    enableIcons = lib.mkEnableOption "icons" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [ pkgs.poppler ]
      ++ lib.optionals cfg.enableIcons [
        config.home-manager.desktop.theme.fonts.symbols.package
      ];

    programs.yazi = {
      enable = true;
      enableFishIntegration = config.home-manager.cli.fish.enable;
      enableZshIntegration = config.home-manager.cli.zsh.enable;
    };
  };
}
