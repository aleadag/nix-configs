{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./fuzzel.nix
    ./hyprland
    ./kanshi
    ./sway.nix
    ./swayidle.nix
    ./swaylock.nix
    ./waybar.nix
  ];

  options.home-manager.desktop.wayland.enable = lib.mkEnableOption "Wayland config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.wayland.enable {
    home.packages = with pkgs; [ wev ];
  };
}
