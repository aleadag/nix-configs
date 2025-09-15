{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin.skhd;
in
{
  options.nix-darwin.skhd.enable = lib.mkEnableOption "skhd config" // {
    default = config.nix-darwin.yabai.enable;
  };

  config = lib.mkIf cfg.enable (
    let
      modeControllerCmd = lib.getExe (import ./mode-controller.nix { inherit pkgs; });
      toggleZenModeCmd = lib.getExe (import ./toggle-zen-mode.nix { inherit pkgs; });
    in
    {
      services.skhd = {
        enable = true;
        package = pkgs.skhd;
        skhdConfig = # bash
          ''
            # Switch to space with window running in native full-screen mode. Only works with SIP disabled.

            # = key
            cmd - 0x18             :  index="$(yabai -m query --spaces --display | \
                                             jq 'map(select(."is-native-fullscreen" == true))[0].index')"; \
                                      yabai -m space --focus "$index"

            # ===== MAIN LAYER (Command key) - Core functionality =====

            # fast focus desktop
            cmd - left             : yabai -m space --focus prev
            cmd - right            : yabai -m space --focus next

            # QWERTY workspace navigation (consistent with Sway/i3)
            cmd - q                : yabai -m space --focus 1
            cmd - w                : yabai -m space --focus 2
            cmd - e                : yabai -m space --focus 3
            cmd - r                : yabai -m space --focus 4
            cmd - t                : yabai -m space --focus 5
            cmd - y                : yabai -m space --focus 6
            cmd - u                : yabai -m space --focus 7
            cmd - i                : yabai -m space --focus 8
            cmd - o                : yabai -m space --focus 9
            cmd - p                : yabai -m space --focus 10

            # Terminal (consistent with Sway: Super+Return)
            cmd - return           : open -na "Kitty"

            # Browser (consistent with Sway: Super+M)
            cmd - m                : open -na "Firefox"

            # Application launcher (consistent with Sway: Super+D)
            # set in Raycat
            # cmd - d                : open -na "Raycast" || open -na "Alfred 5" || open -na "Spotlight"

            # Focus parent/child containers (consistent with Sway: Super+A/C)
            cmd + shift - a                : yabai -m window --focus largest
            cmd + shift - c                : yabai -m window --focus smallest

            cmd + shift - z                : yabai -m space --focus recent

            # Splits (consistent with Sway: Super+V/S)
            cmd + shift - v                : yabai -m window --insert east
            cmd + shift - s                : yabai -m window --insert south

            # Fullscreen (consistent with Sway: Super+F)
            cmd - f                : yabai -m window --toggle zoom-fullscreen

            # Gap controls (consistent with Sway: Super+minus/equal)
            # cmd - 0x1B            : yabai -m space --gap abs:$(($(yabai -m query --spaces --space | jq '.gap') - 6))
            # cmd - 0x18            : yabai -m space --gap abs:$(($(yabai -m query --spaces --space | jq '.gap') + 6))

            # Resize mode entry handled by mode activation below

            # Window switcher by letter (consistent with Sway: Super+B)
            cmd - b                : yabai -m window --focus mouse

            # Window switcher (consistent with Sway: Super+Tab)
            cmd - tab              : yabai -m window --focus recent

            # Workspace switcher (consistent with Sway: Alt+Tab)
            alt - tab              : yabai -m space --focus recent

            # - key
            cmd - 0x1B             : yabai -m window --focus recent

            ############################# Mode definitions ##################################
            # Simplified mode structure to match Sway/i3 + reload for system management
            :: default           : ${modeControllerCmd} default
            :: resize  @         : ${modeControllerCmd} resize
            :: power   @         : ${modeControllerCmd} power
            :: reload  @         : ${modeControllerCmd} reload

            # Mode activation (consistent with Sway/i3)
            cmd - 0x2F             ; resize
            cmd + shift - escape   ; power
            cmd + shift - x        ; reload

            # De-activate modes (consistent with Sway/i3)
            resize, power, reload < escape ; default
            resize, power, reload < return ; default

            ############################# Global modifiers ##################################
            # The aim is to not have too many global key-bindings because it will clash with
            # other application based keybindings e.g. VS Code, IntelliJ, etc.

            # toggle fullscreen inside screen (legacy - use cmd+f instead)
            cmd + shift - space   : yabai -m window --toggle zoom-fullscreen; \
                                    sketchybar --trigger window_focus

            # ===== DANGER LAYER (Command+Shift) - Destructive actions =====

            # Window killing (consistent with Sway: Super+Shift+slash)
            cmd + shift - 0x2C     : yabai -m window --close  # slash key

            # Window movement (consistent with Sway directional movement)
            cmd + shift - h        : yabai -m window --warp west; \
                                     sketchybar --trigger window_focus
            cmd + shift - j        : yabai -m window --warp south; \
                                     sketchybar --trigger window_focus
            cmd + shift - k        : yabai -m window --warp north; \
                                     sketchybar --trigger window_focus
            cmd + shift - l        : yabai -m window --warp east; \
                                     sketchybar --trigger window_focus

            # Floating toggle (consistent with Sway: Super+Shift+F)
            cmd + shift - f        : yabai -m window --toggle float; \
                                     yabai -m window --grid 4:4:1:1:2:2; \
                                     sketchybar --trigger window_focus

            # Move windows to workspaces (QWERTY pattern)
            cmd + shift - q        : yabai -m window --space 1; yabai -m space --focus 1
            cmd + shift - w        : yabai -m window --space 2; yabai -m space --focus 2
            cmd + shift - e        : yabai -m window --space 3; yabai -m space --focus 3
            cmd + shift - r        : yabai -m window --space 4; yabai -m space --focus 4
            cmd + shift - t        : yabai -m window --space 5; yabai -m space --focus 5
            cmd + shift - y        : yabai -m window --space 6; yabai -m space --focus 6
            cmd + shift - u        : yabai -m window --space 7; yabai -m space --focus 7
            cmd + shift - i        : yabai -m window --space 8; yabai -m space --focus 8
            cmd + shift - o        : yabai -m window --space 9; yabai -m space --focus 9
            cmd + shift - p        : yabai -m window --space 10; yabai -m space --focus 10

            # Focus mode toggle (consistent with Sway: Super+Shift+comma)
            cmd + shift - 0x2B     : yabai -m window --focus mouse  # comma key

            # Session control (consistent with Sway: Super+Shift+C)
            cmd + shift - c        : launchctl kickstart -k "gui/502/org.nixos.yabai"; \
                                     launchctl kickstart -k "gui/502/org.nixos.skhd"


            # vi like key bindings (for focus)
            cmd - l                : yabai -m window --focus east || \
                                     yabai -m window --focus west; \
                                     sketchybar --trigger window_focus
            cmd - h                : yabai -m window --focus west || \
                                     yabai -m window --focus east; \
                                     sketchybar --trigger window_focus
            cmd - k                : yabai -m window --focus north || \
                                     yabai -m window --focus stack.prev || \
                                     yabai -m window --focus stack.last; \
                                     sketchybar --trigger window_focus
            cmd - j                : yabai -m window --focus south || \
                                     yabai -m window --focus stack.next || \
                                     yabai -m window --focus stack.first; \
                                     sketchybar --trigger window_focus

            # ===== UTILITY LAYER (Command+Ctrl) - Tools and system controls =====

            # Layout controls in utility layer (consistent with Sway)
            cmd + ctrl - s         : yabai -m space --layout stack
            cmd + ctrl - v         : yabai -m space --layout bsp
            cmd + ctrl - t         : yabai -m query --spaces --space | \
                                     jq -re ".type" | \
                                     xargs -I {} bash -c \
                                     "if [ {} = 'stack' ]; \
                                     then yabai -m space --layout bsp; \
                                     else yabai -m space --layout stack; \
                                     fi"

            # Move workspace to display direction (consistent with Sway: Super+Ctrl+HJKL)
            cmd + ctrl - h         : yabai -m space --display west; yabai -m display --focus west
            cmd + ctrl - j         : yabai -m space --display south; yabai -m display --focus south
            cmd + ctrl - k         : yabai -m space --display north; yabai -m display --focus north
            cmd + ctrl - l         : yabai -m space --display east; yabai -m display --focus east

            # Notification management (consistent with Sway utility layer)
            cmd + ctrl - escape    : osascript -e 'tell application "System Events" to keystroke "x" using {command down, option down}' # close notifications
            cmd + ctrl + shift - escape : osascript -e 'tell application "System Events" to click button "Clear All" of group 1 of UI element 1 of scroll area 1 of group 1 of window "Notification Center" of application process "NotificationCenter"' # close all notifications

            cmd - down           : yabai -m window --focus mouse; \
                                    sketchybar --trigger window_focus

            # toggle window native fullscreen (legacy - moved to utility layer)
            cmd + shift - n       : yabai -m window --toggle native-fullscreen

            # Quit application (consistent with macOS: Super+Alt+Q)
            cmd + alt - q       : osascript -e 'tell application "System Events" to set frontApp to name of first application process whose frontmost is true' -e 'tell application frontApp to quit'

            # Fast focus display (consistent with Sway utility layer pattern)
            cmd + alt - h       : yabai -m display --focus west || yabai -m display --focus recent
            cmd + alt - l       : yabai -m display --focus east || yabai -m display --focus recent
            cmd + alt - k       : yabai -m display --focus north || yabai -m display --focus recent
            cmd + alt - j       : yabai -m display --focus south || yabai -m display --focus recent

            # float / unfloat window and center on screen
            cmd + alt - f                : yabai -m window --toggle float; \
                                           yabai -m window --grid 4:4:1:1:2:2; \
                                           sketchybar --trigger window_focus

            # Close a window. Not the same as quit (legacy - use cmd+shift+slash instead)
            cmd + shift - q       : yabai -m window --close

            # Focus window under mouse
            cmd + ctrl - m       : yabai -m window --focus mouse

            # Toggle zen mode. zooms focused window, removes all margins
            # and hides status bar
            cmd + shift - z       : ${toggleZenModeCmd}; \
                                    skhd -k 'escape'



            ####################### Resize mode ############################################

            # Resize focused window towards left direction (consistent with Sway: 192px/5%)
            resize < h             : yabai -m window --resize left:-192:0 || \
                                     yabai -m window --resize right:-192:0

            # Resize focused window towards down direction (consistent with Sway: 192px/5%)
            resize < j             : yabai -m window --resize bottom:0:192 || \
                                     yabai -m window --resize top:0:192

            # Resize focused window towards up direction (consistent with Sway: 192px/5%)
            resize < k             : yabai -m window --resize top:0:-192 || \
                                     yabai -m window --resize bottom:0:-192

            # Resize focused window towards right direction (consistent with Sway: 192px/5%)
            resize < l             : yabai -m window --resize right:192:0 || \
                                     yabai -m window --resize left:192:0

            # Move floating windows by 192px (consistent with Sway)
            resize < up            : yabai -m window --move rel:0:-192
            resize < down          : yabai -m window --move rel:0:192
            resize < left          : yabai -m window --move rel:-192:0
            resize < right         : yabai -m window --move rel:192:0

            # Balance all windows. Maps to `=` key
            resize < 0x18          : yabai -m space --balance; skhd -k 'escape'

            # Rotate tree by 90 degrees
            resize < r             : yabai -m space --rotate 90

            # Mirror tree y-axis
            resize < y             : yabai -m space --mirror y-axis; \
                                     skhd -k 'escape'

            # Mirror tree x-axis
            resize < x             : yabai -m space --mirror x-axis; \
                                     skhd -k 'escape'

            # Set all windows on active space back to normal
            resize < z             : yabai -m query --windows --space | \
                                     jq -re '.[] | select(."has-fullscreen-zoom" == true) | .id' | \
                                     xargs -I{} yabai -m window {} --toggle zoom-fullscreen; \
                                     skhd -k 'escape'; \
                                     sketchybar --trigger window_focus

            # Swaps the recent window with the window that's currently focused by the mouse
            resize < p              : yabai -m window mouse --swap recent; \
                                      skhd -k 'escape'


            ######################## Power Management Mode ##################################
            # Power management mode (consistent with Sway/i3)

            power < l              : skhd -k 'escape'; pmset displaysleepnow  # lock screen
            power < e              : skhd -k 'escape'; osascript -e 'tell app "System Events" to log out'  # logout
            power < s              : skhd -k 'escape'; pmset sleepnow  # suspend
            power < h              : skhd -k 'escape'; sudo pmset -a hibernatemode 25 && sudo pmset sleepnow  # hibernate
            power < shift - r      : skhd -k 'escape'; sudo shutdown -r now  # reboot
            power < shift - s      : skhd -k 'escape'; sudo shutdown -h now  # shutdown



            ##################### Reload mode ##############################################

            reload < 0            : skhd -k 'escape'; \
                                    launchctl kickstart -k "gui/502/org.nixos.yabai"; \
                                    launchctl kickstart -k "gui/502/org.nixos.sketchybar"; \
                                    launchctl kickstart -k "gui/502/org.nixos.skhd"

            reload < 1            : launchctl kickstart -k "gui/502/org.nixos.yabai"; \
                                    skhd -k 'escape'

            reload < 2            : skhd -k 'escape'; \
                                    launchctl kickstart -k "gui/502/org.nixos.skhd"

            reload < 3            : launchctl kickstart -k "gui/502/org.nixos.sketchybar"; \
                                    skhd -k 'escape'
          '';
      };
    }
  );
}
