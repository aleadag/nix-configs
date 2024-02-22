{ config, lib, pkgs, ... }:
pkgs.writeShellApplication {
  name = "sketchybar-items-mode-indicator";
  text =
    with config.home-manager.desktop.theme;
    with import ../utils.nix { inherit lib; };
    /* bash */ ''
      sketchybar   --add item               mode_indicator center \
                   --set mode_indicator     drawing=off \
                                            label.color="${fixColor colors.base}" \
                                            label.font="SF Pro:Bold:14.0" \
                                            background.padding_left=15 \
                                            background.padding_right=15
    '';
}
