{ config, lib, pkgs, ... }:
{
  options.home-manager.darwin.sketchybar.enable = lib.mkEnableOption "sketchybar config" // {
    default = config.home-manager.darwin.yabai.enable;
  };

  config = lib.mkIf config.home-manager.darwin.sketchybar.enable {
    home.packages = with pkgs; [ sketchybar ];
    xdg.configFile."sketchybar/sketchybarrc" =
      with config.home-manager.desktop.theme;
      let
        itemsSpaces = pkgs.callPackage ./items/spaces.nix { inherit config lib pkgs; };
        itemsFrontApp = pkgs.callPackage ./items/front-app.nix { inherit config lib pkgs; };
        itemsModeIndicator = pkgs.callPackage ./items/mode-indicator.nix { inherit config lib pkgs; };
        sketchybarrc = pkgs.writeShellApplication {
          name = "sketchybarrc";
          runtimeInputs = with pkgs; [ yabai sketchybar ];
          text = let paddings = "10"; shadow = "on"; in
          # bash
            ''
              # Setting up the general bar appearance and default values
              sketchybar --bar     height=30                                         \
                                   shadow=${shadow}                                  \
                                   position=bottom                                   \
                                   padding_right=${paddings}                         \
                                   padding_left=${paddings}                          \
                                   blur_radius=20                                    \
                                   sticky=off                                        \
                                                                                     \
                         --default updates=when_shown                                \
                                   icon.padding_left=${paddings}                     \
                                   icon.padding_right=${paddings}                    \
                                   label.padding_left=${paddings}                    \
                                   label.padding_right=${paddings}                   \
                                   background.height=0                               \
                                   background.padding_right=${paddings}              \
                                   background.padding_left=${paddings}               \
                                   popup.background.border_width=2                   \
                                   popup.background.corner_radius=11                 \
                                   popup.background.shadow.drawing=${shadow}

              # Left
              # shellcheck source=/dev/null
              source "${lib.getExe itemsSpaces}"
              # shellcheck source=/dev/null
              source "${lib.getExe itemsFrontApp}"

              # Center
              # shellcheck source=/dev/null
              source "${lib.getExe itemsModeIndicator}"

              ############## FINALIZING THE SETUP ##############
              sketchybar --update

              echo "sketchybar configuation loaded.."
            '';
        };
      in
      {
        source = lib.getExe sketchybarrc;
      };

    launchd.agents."sketchybar" = {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe pkgs.sketchybar) ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };
  };
}
