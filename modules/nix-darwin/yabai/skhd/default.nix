{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin.yabai;
in
{
  config = lib.mkIf cfg.enable (
    let
      sketchybar = config.services.sketchybar.package;
      yabai = config.services.yabai.package;
      modeControllerPkg = import ./mode-controller.nix {
        inherit
          pkgs
          config
          lib
          sketchybar
          ;
      };
      toggleZenMode = import ./toggle-zen-mode.nix { inherit pkgs yabai sketchybar; };

      # 定义命令变量，简化后续调用
      yabaiCmd = "${lib.getExe yabai}";
      sketchybarCmd = "${lib.getExe sketchybar}";
      modeControllerCmd = "${modeControllerPkg}/bin/skhd-mode-controller";
    in
    {
      services.skhd = {
        enable = true;
        package = pkgs.skhd;
        skhdConfig = # bash
          ''
            # Switch to space with window running in native full-screen mode. Only works with SIP disabled.

            # = key
            ctrl - 0x18            :  index="$(${yabaiCmd} -m query --spaces --display | \
                                             jq 'map(select(."is-native-fullscreen" == true))[0].index')"; \
                                      ${yabaiCmd} -m space --focus "$index"

            # fast focus desktop
            ctrl - left            : ${yabaiCmd} -m space --focus prev
            ctrl - right           : ${yabaiCmd} -m space --focus next
            ctrl - z               : ${yabaiCmd} -m space --focus recent
            ctrl - 1               : ${yabaiCmd} -m space --focus 1
            ctrl - 2               : ${yabaiCmd} -m space --focus 2
            ctrl - 3               : ${yabaiCmd} -m space --focus 3
            ctrl - 4               : ${yabaiCmd} -m space --focus 4
            ctrl - 5               : ${yabaiCmd} -m space --focus 5
            ctrl - 6               : ${yabaiCmd} -m space --focus 6
            ctrl - 7               : ${yabaiCmd} -m space --focus 7
            ctrl - 8               : ${yabaiCmd} -m space --focus 8
            ctrl - 9               : ${yabaiCmd} -m space --focus 9
            ctrl - 0               : ${yabaiCmd} -m space --focus 10
            ctrl + alt - 1         : ${yabaiCmd} -m space --focus 11
            ctrl + alt - 2         : ${yabaiCmd} -m space --focus 12
            ctrl + alt - 3         : ${yabaiCmd} -m space --focus 13
            ctrl + alt - 4         : ${yabaiCmd} -m space --focus 14
            ctrl + alt - 5         : ${yabaiCmd} -m space --focus 15
            ctrl + alt - 6         : ${yabaiCmd} -m space --focus 16
            ctrl + alt - 7         : ${yabaiCmd} -m space --focus 17
            ctrl + alt - 8         : ${yabaiCmd} -m space --focus 18
            ctrl + alt - 9         : ${yabaiCmd} -m space --focus 19
            ctrl + alt - 0         : ${yabaiCmd} -m space --focus 20

            # - key
            ctrl - 0x1B            : ${yabaiCmd} -m window --focus recent

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
            ctrl + shift - space  : ${yabaiCmd} -m window --toggle zoom-fullscreen; \
                                    ${sketchybarCmd} --trigger window_focus

            # vi like key bindings
            ctrl + shift - l      : ${yabaiCmd} -m window --focus east || \
                                    ${yabaiCmd} -m window --focus west; \
                                    ${sketchybarCmd} --trigger window_focus
            ctrl + shift - h      : ${yabaiCmd} -m window --focus west || \
                                    ${yabaiCmd} -m window --focus east; \
                                    ${sketchybarCmd} --trigger window_focus
            ctrl + shift - k      : ${yabaiCmd} -m window --focus north || \
                                    ${yabaiCmd} -m window --focus stack.prev || \
                                    ${yabaiCmd} -m window --focus stack.last; \
                                    ${sketchybarCmd} --trigger window_focus

            ctrl + shift - j      : ${yabaiCmd} -m window --focus south || \
                                    ${yabaiCmd} -m window --focus stack.next || \
                                    ${yabaiCmd} -m window --focus stack.first; \
                                    ${sketchybarCmd} --trigger window_focus

            ctrl - down           : ${yabaiCmd} -m window --focus mouse; \
                                    ${sketchybarCmd} --trigger window_focus

            # toggle window native fullscreen
            ctrl + shift - f      : ${yabaiCmd} -m window --toggle native-fullscreen

            # Fast focus display
            ctrl + alt - h      : ${yabaiCmd} -m display --focus west || ${yabaiCmd} -m display --focus recent
            ctrl + alt - l      : ${yabaiCmd} -m display --focus east || ${yabaiCmd} -m display --focus recent
            ctrl + alt - k      : ${yabaiCmd} -m display --focus north || ${yabaiCmd} -m display --focus recent
            ctrl + alt - j      : ${yabaiCmd} -m display --focus south || ${yabaiCmd} -m display --focus recent

            # float / unfloat window and center on screen
            alt - f                : ${yabaiCmd} -m window --toggle float; \
                                     ${yabaiCmd} -m window --grid 4:4:1:1:2:2; \
                                     ${sketchybarCmd} --trigger window_focus

            # Close a window. Not the same as quit
            ctrl + shift - q     : ${yabaiCmd} -m window --close

            # Focus window under mouse
            cmd - m              : ${yabaiCmd} -m window --focus mouse

            # Toggle zen mode. zooms focused window, removes all margins
            # and hides status bar
            ctrl + shift - z      : ${toggleZenMode}/bin/skhd-toggle-zen-mode; \
                                    skhd -k 'escape'


            ######################## Insert mode ###########################################

            inst < h            : ${yabaiCmd} -m window --insert west; skhd -k 'escape'
            inst < j            : ${yabaiCmd} -m window --insert south; skhd -k 'escape'
            inst < k            : ${yabaiCmd} -m window --insert north; skhd -k 'escape'
            inst < l            : ${yabaiCmd} -m window --insert east; skhd -k 'escape'
            inst < s            : ${yabaiCmd} -m window --insert stack; skhd -k 'escape'

            ######################## Stack mode ############################################

            # Add the active window  to the window or stack to the {direction}
            # Note that this only works when the active window does *not* already belong to a stack
            stack < h              : ${yabaiCmd} -m window west  \
                                     --stack "$(${yabaiCmd} -m query --windows --window | jq -r '.id')"; \
                                     skhd -k 'escape'

            stack < j              : ${yabaiCmd} -m window south \
                                     --stack "$(${yabaiCmd} -m query --windows --window | jq -r '.id')" ; \
                                     skhd -k 'escape'

            stack < k              : ${yabaiCmd} -m window north \
                                     --stack "$(${yabaiCmd} -m query --windows --window | jq -r '.id')" ; \
                                     skhd -k 'escape'

            stack < l              : ${yabaiCmd} -m window east  \
                                     --stack "$(${yabaiCmd} -m query --windows --window | jq -r '.id')"; \
                                     skhd -k 'escape'

            # Toggle current space layout between stack and bsp
            stack < space          : ${yabaiCmd} -m query --spaces --space | \
                                     jq -re ".type" | \
                                     xargs -I {} bash -c \
                                     "if [ {} = 'stack' ]; \
                                     then ${yabaiCmd} -m space --layout bsp; \
                                     else ${yabaiCmd} -m space --layout stack; \
                                     fi"; \
                                     skhd -k 'escape'

            # Remove the current window from the stack. Only works if the space layout is bsp
            stack < b              : window="$(${yabaiCmd} -m query --windows --window | jq -r '.id')"; \
                                     ${yabaiCmd} -m window east --stack $window || \
                                     (${yabaiCmd} -m window $window --toggle float && ${yabaiCmd} -m window $window --toggle float); \
                                     skhd -k 'escape'

            # Stack all windows in the currect space on top of the current window while keeping the current space layout in bsp
            stack < s              : window="$(${yabaiCmd} -m query --windows --window | jq -r '.id')" && \
                                     ${yabaiCmd} -m query --windows --space | jq -rc --arg w "$window" '[.[].id] | map(select(. != $w)) | .[]' | \
                                     xargs -I {} ${yabaiCmd} -m window "$window" --stack {}; \
                                     skhd -k 'escape'

            ####################### Resize mode ############################################

            # Resize focused window towards left direction
            resize < h             : ${yabaiCmd} -m window --resize left:-100:0 || \
                                     ${yabaiCmd} -m window --resize right:-100:0

            # Resize focused window towards down direction
            resize < j             : ${yabaiCmd} -m window --resize bottom:0:100 || \
                                     ${yabaiCmd} -m window --resize top:0:100

            # Resize focused window towards up direction
            resize < k             : ${yabaiCmd} -m window --resize top:0:-100 || \
                                     ${yabaiCmd} -m window --resize bottom:0:-100

            # Resize focused window towards right direction
            resize < l             : ${yabaiCmd} -m window --resize right:100:0 || \
                                     ${yabaiCmd} -m window --resize left:100:0

            # Balance all windows. Maps to `=` key
            resize < 0x18          : ${yabaiCmd} -m space --balance; skhd -k 'escape'

            # Rotate tree by 90 degrees
            resize < r             : ${yabaiCmd} -m space --rotate 90

            # Mirror tree y-axis
            resize < y             : ${yabaiCmd} -m space --mirror y-axis; \
                                     skhd -k 'escape'

            # Mirror tree x-axis
            resize < x             : ${yabaiCmd} -m space --mirror x-axis; \
                                     skhd -k 'escape'

            # Set all windows on active space back to normal
            resize < z             : ${yabaiCmd} -m query --windows --space | \
                                     jq -re '.[] | select(."has-fullscreen-zoom" == true) | .id' | \
                                     xargs -I{} ${yabaiCmd} -m window {} --toggle zoom-fullscreen; \
                                     skhd -k 'escape'; \
                                     ${sketchybarCmd} --trigger window_focus

            # Swaps the recent window with the window that's currently focused by the mouse
            resize < p              : ${yabaiCmd} -m window mouse --swap recent; \
                                      skhd -k 'escape'


            ############################ Display mode ######################################

            # Focus previous display , (Like <)
            display < 0x2F         : ${yabaiCmd} -m display --focus prev || \
                                     ${yabaiCmd} -m display --focus next; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Focus next display . (Like >)
            display < 0x2B         : ${yabaiCmd} -m display --focus next || \
                                     ${yabaiCmd} -m display --focus prev; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to north/up display and follow focus
            display < k            : ${yabaiCmd} -m window --display north; \
                                     ${yabaiCmd} -m display --focus north; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to down/south display and follow focus
            display < j            : ${yabaiCmd} -m window --display south; \
                                     ${yabaiCmd} -m display --focus south; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to right/east display and follow focus
            display < l            : ${yabaiCmd} -m window --display east; \
                                     ${yabaiCmd} -m display --focus east; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Send window to left/west display and follow focus
            display < h            : ${yabaiCmd} -m window --display west; \
                                     ${yabaiCmd} -m display --focus west; \
                                     ${sketchybarCmd} --trigger windows_on_spaces; \
                                     skhd -k 'escape'

            # Focus display by number
            display < 1           : ${yabaiCmd} -m display --focus 1; skhd -k 'escape'
            display < 2           : ${yabaiCmd} -m display --focus 2; skhd -k 'escape'
            display < 3           : ${yabaiCmd} -m display --focus 3; skhd -k 'escape'
            display < 4           : ${yabaiCmd} -m display --focus 4; skhd -k 'escape'

            ##################### Window mode ##############################################

            # create desktop, send window to new desktop and follow focus
            window < c            : ${yabaiCmd} -m space --create; \
                                    index="$(${yabaiCmd} -m query --spaces --display | jq 'map(select(."native-fullscreen" == 0))[-1].index')"; \
                                    ${yabaiCmd} -m window --space "$index"; \
                                    ${yabaiCmd} -m space --focus "$index"; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # destroy current desktop and follow focus to previous desktop
            window < x            : index="$(${yabaiCmd} -m query --spaces --space | jq '.index - 1')"; \
                                    ${yabaiCmd} -m space --destroy; \
                                    ${yabaiCmd} -m space --focus "$index"; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # toggle window native fullscreen
            window < f            : ${yabaiCmd} -m window --toggle native-fullscreen; skhd -k 'escape'

            # send current window to i-th space and follow focus* (* requires SIP disabled)
            window < left         : ${yabaiCmd} -m window --space prev; \
                                    ${yabaiCmd} -m space --focus prev; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < right        : ${yabaiCmd} -m window --space next; \
                                    ${yabaiCmd} -m space --focus next; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # change position of window on the current space
            window < h            : ${yabaiCmd} -m window --warp west; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < j            : ${yabaiCmd} -m window --warp south; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < k            : ${yabaiCmd} -m window --warp north; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < l            : ${yabaiCmd} -m window --warp east; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # send window to specified space
            window < 1            : ${yabaiCmd} -m window --space 1; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 2            : ${yabaiCmd} -m window --space 2; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 3            : ${yabaiCmd} -m window --space 3; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 4            : ${yabaiCmd} -m window --space 4; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 5            : ${yabaiCmd} -m window --space 5; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 6            : ${yabaiCmd} -m window --space 6; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 7            : ${yabaiCmd} -m window --space 7; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 8            : ${yabaiCmd} -m window --space 8; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            window < 9            : ${yabaiCmd} -m window --space 9; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < 0            : ${yabaiCmd} -m window --space 10; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            window < alt - 1      : ${yabaiCmd} -m window --space 11; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < alt - 2      : ${yabaiCmd} -m window --space 12; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'
            window < alt - 3      : ${yabaiCmd} -m window --space 13; \
                                    ${sketchybarCmd} --trigger windows_on_spaces; \
                                    skhd -k 'escape'

            # Switch layout of current desktop between bsp and stack
            window < space        : ${yabaiCmd} -m query --spaces --space | \
                                    jq -re ".type" | \
                                    xargs -I {} bash -c \
                                    "if [ {} = 'stack' ]; \
                                    then ${yabaiCmd} -m space --layout bsp; \
                                    else ${yabaiCmd} -m space --layout stack; \
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
