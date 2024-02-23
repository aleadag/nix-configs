{ config, lib, pkgs, ... }:
pkgs.writeShellApplication {
  name = "skhd-mode-controller";
  text =
    with config.home-manager.desktop.theme;
    with import ../sketchybar/utils.nix { inherit lib; };
    /* bash */ ''
      case "$1" in
      default)
        sketchybar  --bar           color=${fixColor colors.base} \
                    --set /space.*/ label.background.color=${fixColor colors.crust} \
                    --set /space.*/ icon.color=${fixColor colors.text} \
                    --set /space.*/ label.color=${fixColor colors.text} \
                    --set separator icon.color=${fixColor colors.rosewater} \
                    --trigger mode_changed \
                    --set mode_indicator label="" \
                    --set system.yabai label.color=${fixColor colors.text} \
                    --set front_app label.color=${fixColor colors.text} \
                    --set mode_indicator drawing=off
        ;;
      stack)
        sketchybar  --bar           color=${fixColor colors.teal} \
                    --set /space.*/ label.background.color=${fixColor colors.teal} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set /space.*/ label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator label="[STACK]"
        ;;
      display)
        sketchybar  --bar           color=${fixColor colors.pink} \
                    --set /space.*/ label.background.color=${fixColor colors.pink} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set /space.*/ label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator label="[DISPLAY]"
        ;;
      window)
        sketchybar  --bar           color=${fixColor colors.yellow} \
                    --set /space.*/ label.background.color=${fixColor colors.yellow} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set /space.*/ label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator label="[WINDOW]"
        ;;
      resize)
        sketchybar  --bar           color=${fixColor colors.green} \
                    --set /space.*/ label.background.color=${fixColor colors.green} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set /space.*/ label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator label="[RESIZE]"
        ;;
      inst)
        sketchybar  --bar           color=${fixColor colors.blue} \
                    --set /space.*/ label.background.color=${fixColor colors.blue} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set /space.*/ label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator label="[INSERT]"
        ;;
      reload)
        sketchybar  --bar           color=${fixColor colors.red} \
                    --set /space.*/ label.background.color=${fixColor colors.red} \
                    --set /space.*/ icon.color=${fixColor colors.base} \
                    --set system.yabai label.color=${fixColor colors.base} \
                    --set separator icon.color=${fixColor colors.base} \
                    --set front_app label.color=${fixColor colors.base} \
                    --set mode_indicator drawing=on \
                    --set mode_indicator label="[RELOAD] 1:YABAI, 2:SKHD, 3:SKETCHYBAR, 0:ALL"
        ;;
      esac
    '';
}
