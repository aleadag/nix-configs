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
            ctrl - 0x18            :  index="$(yabai -m query --spaces --display | \
                                             jq 'map(select(."is-native-fullscreen" == true))[0].index')"; \
                                      yabai -m space --focus "$index"

            # fast focus desktop
            ctrl - left            : yabai -m space --focus prev
            ctrl - right           : yabai -m space --focus next
            ctrl - z               : yabai -m space --focus recent
            ctrl - 1               : yabai -m space --focus 1
            ctrl - 2               : yabai -m space --focus 2
            ctrl - 3               : yabai -m space --focus 3
            ctrl - 4               : yabai -m space --focus 4
            ctrl - 5               : yabai -m space --focus 5
            ctrl - 6               : yabai -m space --focus 6
            ctrl - 7               : yabai -m space --focus 7
            ctrl - 8               : yabai -m space --focus 8
            ctrl - 9               : yabai -m space --focus 9
            ctrl - 0               : yabai -m space --focus 10
            ctrl + alt - 1         : yabai -m space --focus 11
            ctrl + alt - 2         : yabai -m space --focus 12
            ctrl + alt - 3         : yabai -m space --focus 13
            ctrl + alt - 4         : yabai -m space --focus 14
            ctrl + alt - 5         : yabai -m space --focus 15
            ctrl + alt - 6         : yabai -m space --focus 16
            ctrl + alt - 7         : yabai -m space --focus 17
            ctrl + alt - 8         : yabai -m space --focus 18
            ctrl + alt - 9         : yabai -m space --focus 19
            ctrl + alt - 0         : yabai -m space --focus 20

            # - key
            ctrl - 0x1B            : yabai -m window --focus recent

            ############################# Mode definitions ##################################
            :: default           : ${modeControllerCmd} default # default mode: normal
            :: stack   @         : ${modeControllerCmd} stack # stack mode: interact with stacks
            :: display @         : ${modeControllerCmd} display # display mode: focus displays, move windows to other displays
            :: window  @         : ${modeControllerCmd} window # window mode: manipulate windows and spaces
            :: resize  @         : ${modeControllerCmd} resize # resize mode: resize windows in current space
            :: inst    @         : ${modeControllerCmd} inst # insert mode: tell yabai where to insert the new window
            :: reload  @         : ${modeControllerCmd} reload # reload mode: restart services

            # Hack to use "ctrl + shift - r" keybinding in RubyMine
            # to run tests but trigger resize mode everywhere else
            # meh is (shift + alt + ctrl)
            default < ctrl + shift - r [
              "code"   ~
              * : skhd -k "meh - r"
            ]

            resize < ctrl + shift - r [
              "code"   ~
              * : skhd -k "meh - r"
            ]

            # Activate modes using the keybinding
            default < ctrl + shift - d ; display
            default < ctrl + shift - s ; stack
            default < ctrl + shift - w ; window
            default < meh - r          ; resize
            default < ctrl + shift - i ; inst
            default < ctrl + shift - x ; reload

            # De-activate modes
            display, window, resize, stack, inst, reload < escape ; default

            display < ctrl + shift - d ; default
            stack   < ctrl + shift - s ; default
            window  < ctrl + shift - w ; default
            resize  < meh - r          ; default
            inst    < ctrl + shift - i ; default
            reload  < ctrl + shift - x ; default

            # Launch other modes from within a mode
            # display, stack, window, resize, inst, reload
            stack, window, resize, inst, reload    < d ; display
            display, window, resize, inst, reload  < s ; stack
            display, stack, resize, inst, reload   < w ; window
            display, stack, window, inst, reload   < r ; resize
            display, stack, window, resize, reload < i ; inst

            ############################# Global modifiers ##################################
            # The aim is to not have too many global key-bindings because it will clash with
            # other application based keybindings e.g. VS Code, IntelliJ, etc.

            # toggle fullscreen inside screen
            ctrl + shift - space  : yabai -m window --toggle zoom-fullscreen; \
                                    sketchybar --trigger window_focus

            # vi like key bindings
            ctrl + shift - l      : yabai -m window --focus east || \
                                    yabai -m window --focus west; \
                                    sketchybar --trigger window_focus
            ctrl + shift - h      : yabai -m window --focus west || \
                                    yabai -m window --focus east; \
                                    sketchybar --trigger window_focus
            ctrl + shift - k      : yabai -m window --focus north || \
                                    yabai -m window --focus stack.prev || \
                                    yabai -m window --focus stack.last; \
                                    sketchybar --trigger window_focus

            ctrl + shift - j      : yabai -m window --focus south || \
                                    yabai -m window --focus stack.next || \
                                    yabai -m window --focus stack.first; \
                                    sketchybar --trigger window_focus

            ctrl - down           : yabai -m window --focus mouse; \
                                    sketchybar --trigger window_focus

            # toggle window native fullscreen
            ctrl + shift - f      : yabai -m window --toggle native-fullscreen

            # Fast focus display
            ctrl + alt - h      : yabai -m display --focus west || yabai -m display --focus recent
            ctrl + alt - l      : yabai -m display --focus east || yabai -m display --focus recent
            ctrl + alt - k      : yabai -m display --focus north || yabai -m display --focus recent
            ctrl + alt - j      : yabai -m display --focus south || yabai -m display --focus recent

            # float / unfloat window and center on screen
            alt - f                : yabai -m window --toggle float; \
                                     yabai -m window --grid 4:4:1:1:2:2; \
                                     sketchybar --trigger window_focus

            # Close a window. Not the same as quit
            ctrl + shift - q     : yabai -m window --close

            # Focus window under mouse
            cmd - m              : yabai -m window --focus mouse

            # Toggle zen mode. zooms focused window, removes all margins
            # and hides status bar
            ctrl + shift - z      : ${toggleZenModeCmd}; \
                                    skhd -k 'escape'


            ######################## Insert mode ###########################################

            inst < h            : yabai -m window --insert west; skhd -k 'escape'
            inst < j            : yabai -m window --insert south; skhd -k 'escape'
            inst < k            : yabai -m window --insert north; skhd -k 'escape'
            inst < l            : yabai -m window --insert east; skhd -k 'escape'
            inst < s            : yabai -m window --insert stack; skhd -k 'escape'

            ######################## Stack mode ############################################

            # Add the active window  to the window or stack to the {direction}
            # Note that this only works when the active window does *not* already belong to a stack
            stack < h              : yabai -m window west  \
                                     --stack "$(yabai -m query --windows --window | jq -r '.id')"; \
                                     skhd -k 'escape'

            stack < j              : yabai -m window south \
                                     --stack "$(yabai -m query --windows --window | jq -r '.id')" ; \
                                     skhd -k 'escape'

            stack < k              : yabai -m window north \
                                     --stack "$(yabai -m query --windows --window | jq -r '.id')" ; \
                                     skhd -k 'escape'

            stack < l              : yabai -m window east  \
                                     --stack "$(yabai -m query --windows --window | jq -r '.id')"; \
                                     skhd -k 'escape'

            # Toggle current space layout between stack and bsp
            stack < space          : yabai -m query --spaces --space | \
                                     jq -re ".type" | \
                                     xargs -I {} bash -c \
                                     "if [ {} = 'stack' ]; \
                                     then yabai -m space --layout bsp; \
                                     else yabai -m space --layout stack; \
                                     fi"; \
                                     skhd -k 'escape'

            # Remove the current window from the stack. Only works if the space layout is bsp
            stack < b              : window="$(yabai -m query --windows --window | jq -r '.id')"; \
                                     yabai -m window east --stack $window || \
                                     (yabai -m window $window --toggle float && yabai -m window $window --toggle float); \
                                     skhd -k 'escape'

            # Stack all windows in the currect space on top of the current window while keeping the current space layout in bsp
            stack < s              : window="$(yabai -m query --windows --window | jq -r '.id')" && \
                                     yabai -m query --windows --space | jq -rc --arg w "$window" '[.[].id] | map(select(. != $w)) | .[]' | \
                                     xargs -I {} yabai -m window "$window" --stack {}; \
                                     skhd -k 'escape'

            ####################### Resize mode ############################################

            # Resize focused window towards left direction
            resize < h             : yabai -m window --resize left:-100:0 || \
                                     yabai -m window --resize right:-100:0

            # Resize focused window towards down direction
            resize < j             : yabai -m window --resize bottom:0:100 || \
                                     yabai -m window --resize top:0:100

            # Resize focused window towards up direction
            resize < k             : yabai -m window --resize top:0:-100 || \
                                     yabai -m window --resize bottom:0:-100

            # Resize focused window towards right direction
            resize < l             : yabai -m window --resize right:100:0 || \
                                     yabai -m window --resize left:100:0

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


            ############################ Display mode ######################################

            # Focus previous display , (Like <)
            display < 0x2F         : yabai -m display --focus prev || \
                                     yabai -m display --focus next; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Focus next display . (Like >)
            display < 0x2B         : yabai -m display --focus next || \
                                     yabai -m display --focus prev; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to north/up display and follow focus
            display < k            : yabai -m window --display north; \
                                     yabai -m display --focus north; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to down/south display and follow focus
            display < j            : yabai -m window --display south; \
                                     yabai -m display --focus south; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to right/east display and follow focus
            display < l            : yabai -m window --display east; \
                                     yabai -m display --focus east; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to left/west display and follow focus
            display < h            : yabai -m window --display west; \
                                     yabai -m display --focus west; \
                                     sketchybar --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Focus display by number
            display < 1           : yabai -m display --focus 1; skhd -k 'escape'
            display < 2           : yabai -m display --focus 2; skhd -k 'escape'
            display < 3           : yabai -m display --focus 3; skhd -k 'escape'
            display < 4           : yabai -m display --focus 4; skhd -k 'escape'

            ##################### Window mode ##############################################

            # create desktop, send window to new desktop and follow focus
            window < c            : yabai -m space --create; \
                                    index="$(yabai -m query --spaces --display | jq 'map(select(."native-fullscreen" == 0))[-1].index')"; \
                                    yabai -m window --space "$index"; \
                                    yabai -m space --focus "$index"; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # destroy current desktop and follow focus to previous desktop
            window < x            : index="$(yabai -m query --spaces --space | jq '.index - 1')"; \
                                    yabai -m space --destroy; \
                                    yabai -m space --focus "$index"; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # toggle window native fullscreen
            window < f            : yabai -m window --toggle native-fullscreen; skhd -k 'escape'

            # send current window to i-th space and follow focus* (* requires SIP disabled)
            window < left         : yabai -m window --space prev; \
                                    yabai -m space --focus prev; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < right        : yabai -m window --space next; \
                                    yabai -m space --focus next; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # change position of window on the current space
            window < h            : yabai -m window --warp west; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < j            : yabai -m window --warp south; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < k            : yabai -m window --warp north; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < l            : yabai -m window --warp east; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # send window to specified space
            window < 1            : yabai -m window --space 1; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 2            : yabai -m window --space 2; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 3            : yabai -m window --space 3; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 4            : yabai -m window --space 4; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 5            : yabai -m window --space 5; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 6            : yabai -m window --space 6; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 7            : yabai -m window --space 7; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 8            : yabai -m window --space 8; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            window < 9            : yabai -m window --space 9; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 0            : yabai -m window --space 10; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            window < alt - 1      : yabai -m window --space 11; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < alt - 2      : yabai -m window --space 12; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < alt - 3      : yabai -m window --space 13; \
                                    sketchybar --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # Switch layout of current desktop between bsp and stack
            window < space        : yabai -m query --spaces --space | \
                                    jq -re ".type" | \
                                    xargs -I {} bash -c \
                                    "if [ {} = 'stack' ]; \
                                    then yabai -m space --layout bsp; \
                                    else yabai -m space --layout stack; \
                                    fi"; \
                                    skhd -k 'escape'

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
