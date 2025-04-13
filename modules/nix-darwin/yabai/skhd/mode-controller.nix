{
  config,
  lib,
  pkgs,
  sketchybar,
  ...
}:
pkgs.writeShellApplication {
  name = "skhd-mode-controller";
  runtimeInputs = [
    sketchybar
  ];
  text =
    # bash
    ''
      case "$1" in
      default)
        sketchybar  --bar           color=0xFF1e1e2e \
                    --trigger mode_changed \
                    --set mode_indicator label="" \
                    --set system.yabai label.color=0xFFcdd6f4 \
                    --set front_app label.color=0xFFcdd6f4 \
                    --set mode_indicator drawing=off
        ;;
      stack)
        sketchybar  --bar           color=0xFF94e2d5 \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator label="[STACK]"
        ;;
      display)
        sketchybar  --bar           color=0xFFf5c2e7 \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator label="[DISPLAY]"
        ;;
      window)
        sketchybar  --bar           color=0xFFf9e2af \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator label="[WINDOW]"
        ;;
      resize)
        sketchybar  --bar           color=0xFFa6e3a1 \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator label="[RESIZE]"
        ;;
      inst)
        sketchybar  --bar           color=0xFF89b4fa \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator label="[INSERT]"
        ;;
      reload)
        sketchybar  --bar           color=0xFFf38ba8 \
                    --set system.yabai label.color=0xFF11111b \
                    --set front_app label.color=0xFF11111b \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[RELOAD] 1:YABAI, 2:SKHD, 3:SKETCHYBAR, 0:ALL"
        ;;
      esac
    '';
}
