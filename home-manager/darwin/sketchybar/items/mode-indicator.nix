{ config, lib, pkgs, ... }:
pkgs.writeShellApplication {
  name = "sketchybar-items-mode-indicator";
  text = with config.home-manager.desktop.theme;
    let
      fixColor = color: "0xb3${lib.removePrefix "#" color}";
    in
    # bash
    ''
      sketchybar   --add item               mode_indicator center \
                   --set mode_indicator     drawing=off \
                                            label.color="${fixColor colors.surface1}" \
                                            label.font="SF Pro:Bold:14.0" \
                                            background.padding_left=15 \
                                            background.padding_right=15
    '';
}
